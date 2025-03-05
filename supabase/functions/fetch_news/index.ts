import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const SUPABASE_URL = Deno.env.get("MY_SUPABASE_URL")!;
  const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const OPENAI_KEY = Deno.env.get("OPENAI_KEY")!;
  const GNEWS_API_KEY = "ef0dbc3144b8aab6fc32dc0cf7058340";

  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
  const logs: string[] = [];
  const today = new Date().toISOString().split("T")[0];
  const gnewsApiUrl = `https://gnews.io/api/v4/search?q=Taylor+Swift&lang=en&from=${today}&to=${today}&max=10&apikey=${GNEWS_API_KEY}`;

  try {
    const newsResponse = await fetch(gnewsApiUrl);
    if (!newsResponse.ok) {
      throw new Error(`GNews API fetch failed: ${newsResponse.status} ${newsResponse.statusText}`);
    }

    const newsData = await newsResponse.json();

    for (const article of newsData.articles) {
      const { title: headline, url: sourceUrl, image: imageUrl } = article;

      if (!headline.toLowerCase().includes("taylor swift")) {
        logs.push(`❌ Skipping unrelated article: ${headline}`);
        continue;
      }

      const { data: recentArticle, error: fetchError } = await supabase
        .from("ai_articles")
        .select("id, created_at")
        .eq("source_url", sourceUrl)
        .gte("created_at", new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
        .maybeSingle();

      if (fetchError || recentArticle) {
        continue;
      }

      let uploadedImagePath = null;
      if (imageUrl && imageUrl.startsWith("http")) {
        try {
          const imageResponse = await fetch(imageUrl);
          if (imageResponse.ok && imageResponse.headers.get("content-type")?.includes("image")) {
            const imageData = await imageResponse.arrayBuffer();
            const imagePath = `news-images/${crypto.randomUUID()}.jpg`;

            const { data, error } = await supabase.storage
              .from("news-images")
              .upload(imagePath, imageData, { contentType: "image/jpeg" });

            if (!error) {
              uploadedImagePath = imagePath;
            }
          }
        } catch {
          continue;
        }
      } else {
        continue;
      }

      const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${OPENAI_KEY}`,
        },
        body: JSON.stringify({
          model: "gpt-4",
          messages: [
            { role: "system", content: "You are a journalist providing concise, fact-based news. Do not include fictional or speculative content. Do not mention the source or the name of the publisher." },
            { role: "user", content: `Write a short online article based on the following headline and source. Do NOT reference the source name or website. If possible, include quotes from Taylor Swift. Only use verified details from the headline and description:\n\nHeadline: '${headline}'\n\nURL: ${sourceUrl}` }
          ],
          max_tokens: 200
        }),
      });

      const aiData = await aiResponse.json();
      logs.push(`OpenAI response: ${JSON.stringify(aiData)}`); // Log the OpenAI response for debugging
      const aiContent = aiData.choices?.[0]?.message?.content || "AI content unavailable";

      if (aiContent === "AI content unavailable") {
        logs.push(`❌ Skipping article due to AI content unavailable: ${headline}`);
        continue;
      }

      const headlineResponse = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${OPENAI_KEY}`,
        },
        body: JSON.stringify({
          model: "gpt-4",
          messages: [
            { role: "system", content: "You are a journalist specializing in writing clear, engaging, and factual news headlines. Your task is to rewrite headlines while keeping them truthful and accurate." },
            { role: "user", content: `Rewrite this headline to make it more engaging but still accurate. Keep it short: "${headline}"` }
          ],
          max_tokens: 50
        }),
      });

      const headlineData = await headlineResponse.json();
      logs.push(`OpenAI headline response: ${JSON.stringify(headlineData)}`); // Log the OpenAI headline response for debugging
      let rewrittenHeadline = headlineData.choices?.[0]?.message?.content || headline;

      // Trim any leading or trailing whitespace and quotes
      rewrittenHeadline = rewrittenHeadline.trim().replace(/^"|"$/g, '');

      const unwantedPhrases = [
        "I'm sorry",
        "I can't provide a summary",
        "I cannot summarize",
        "Consent Form",
        "not an actual news story",
      ];

      if (unwantedPhrases.some(phrase => aiContent.includes(phrase))) {
        logs.push(`❌ Skipping article due to poor AI response: ${headline} | AI Response: ${aiContent}`);
        continue;
      }

      const { error: insertError } = await supabase.from("ai_articles").insert([
        { 
          title: rewrittenHeadline, 
          ai_content: aiContent, 
          image_path: uploadedImagePath, 
          source_url: sourceUrl,
          created_at: new Date().toISOString()  
        }
      ]);

      if (!insertError) {
        logs.push("✅ Article inserted successfully!");
      }
    }

    return new Response(
      JSON.stringify({ 
        message: "Taylor Swift news articles stored successfully!", 
        logs: logs
      }), 
      { status: 200, headers: { "Content-Type": "application/json" } }
    );

  } catch (error) {
    logs.push(`Error: ${error.message}`);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
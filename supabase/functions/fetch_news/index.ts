import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const SUPABASE_URL = Deno.env.get("MY_SUPABASE_URL")!;
  const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const OPENAI_KEY = Deno.env.get("OPENAI_KEY")!;
  const GNEWS_API_KEY = "ef0dbc3144b8aab6fc32dc0cf7058340";

  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
  const logs: string[] = [];

  const { pathname } = new URL(req.url);
  
  if (req.method === "POST" && pathname === "/chat_taylor") {
    // Handle Chat Request
    try {
      const { message } = await req.json();

      if (!message) {
        return new Response(JSON.stringify({ error: "Message is required" }), { status: 400 });
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
            { role: "system", content: "You are Taylor Swift. Respond like her in a friendly, engaging, and fun tone." },
            { role: "user", content: message }
          ],
          max_tokens: 100,
        }),
      });

      const aiData = await aiResponse.json();
      const aiReply = aiData.choices?.[0]?.message?.content || "Sorry, I can't reply right now.";

      return new Response(JSON.stringify({ reply: aiReply }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });

    } catch (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }
  }

  if (req.method === "POST" && pathname === "/fetch_news") {
    // Handle News Fetching (existing functionality)
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

        let uploadedImagePath = null;
        if (imageUrl && imageUrl.startsWith("http")) {
          try {
            const imageResponse = await fetch(imageUrl);
            if (imageResponse.ok && imageResponse.headers.get("content-type")?.includes("image")) {
              const imageData = await imageResponse.arrayBuffer();
              const imagePath = `news-images/${crypto.randomUUID()}.jpg`;

              const { error } = await supabase.storage
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
              { role: "user", content: `Write a short online article based on the following headline and source:\n\nHeadline: '${headline}'\n\nURL: ${sourceUrl}` }
            ],
            max_tokens: 200,
          }),
        });

        const aiData = await aiResponse.json();
        const aiContent = aiData.choices?.[0]?.message?.content || "AI content unavailable";

        if (aiContent === "AI content unavailable") {
          continue;
        }

        const { error: insertError } = await supabase.from("ai_articles").insert([
          { 
            title: headline, 
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
        JSON.stringify({ message: "Taylor Swift news articles stored successfully!", logs }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );

    } catch (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }
  }

  return new Response(JSON.stringify({ error: "Invalid route" }), { status: 404 });
});
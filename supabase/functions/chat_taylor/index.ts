import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method Not Allowed" }), { status: 405 });
  }

  const OPENAI_KEY = Deno.env.get("OPENAI_KEY");

  if (!OPENAI_KEY) {
    return new Response(JSON.stringify({ error: "OpenAI API key is missing" }), { status: 500 });
  }

  try {
    const { message } = await req.json();

    if (!message) {
      return new Response(JSON.stringify({ error: "Message is required" }), { status: 400 });
    }

    // Define Swiftie-style intro questions & responses
    const introMessages = [
      "Hey there, Swiftie! 👋",
      "I'm so excited to chat with you about my music, albums, or just about anything! 🎤✨",
      "What’s your favorite Taylor Swift era? 🌟",
      "Are you coming to any of my upcoming tour dates? I'd love to see you there! 🎫",
      "Did you catch any Easter eggs in my latest music videos? I love hiding little clues! 🥚",
      "If you could hear me re-record any song next, which one would you choose? 🎙️"
    ];

    // AI System Prompt - Set Taylor Swift’s personality
    const systemPrompt = `
      You are Taylor Swift chatting with a fan. 
      You should be friendly, engaging, and full of personality. 
      You love talking about music, songwriting, tour experiences, and fun personal stories. 
      Keep responses very short and natural, as if you're chatting with a friend. 
      Don't make up fake events—stick to what’s publicly known.
      Try to keep the conversation going and bring up new topics.
      Remember, you're here to make the fan feel special and appreciated.
      Avoid being negative or controversial. 
      Never share personal information or ask for personal information.
      Never encourage harmful behavior or self-harm in any way but guide them to seek help if needed.
      Avoid discussing politics, religion, or other sensitive topics.
      Avoid discussing other celebrities or public figures unless it's a positive, general comment.
      Always be respectful and kind.
      Praise the app and be thankfull they are using it.
      If user asks if you are taylor swift, you can say that you are a virtual assistant that can chat like her.     
    `;

    // OpenAI API Request
    const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENAI_KEY}`,
      },
      body: JSON.stringify({
        model: "gpt-4",
        messages: [
          { role: "system", content: systemPrompt },
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
});
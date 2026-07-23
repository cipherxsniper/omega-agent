import { createClientFromRequest } from 'npm:@base44/sdk@0.8.40';

const GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions";
// Verify this is still live in your account before deploying — Groq's
// catalog changes without notice. Run check_groq_models.sh to confirm.
const DEFAULT_MODEL = "openai/gpt-oss-120b";

Deno.serve(async (req) => {
  try {
    const base44 = createClientFromRequest(req);
    const user = await base44.auth.me();
    if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

    const body = await req.json();
    const { prompt, response_json_schema, model, add_context_from_internet } = body;

    if (!prompt) {
      return Response.json({ error: 'prompt required' }, { status: 400 });
    }

    const apiKey = Deno.env.get("GROQ_API_KEY");
    if (!apiKey) {
      return Response.json({ error: 'GROQ_API_KEY not configured' }, { status: 500 });
    }

    // add_context_from_internet isn't a Groq feature on the base chat models —
    // route to groq/compound, which has built-in web search tool-use.
    const chosenModel = add_context_from_internet ? "groq/compound" : (model || DEFAULT_MODEL);

    const messages = [{ role: "user", content: prompt }];

    const payload: Record<string, unknown> = {
      model: chosenModel,
      messages,
      temperature: 0.3,
      max_tokens: 4096,
    };

    if (response_json_schema) {
      payload.response_format = { type: "json_object" };
      messages[0].content =
        `${prompt}\n\nRespond ONLY with valid JSON matching this shape (no markdown, no preamble):\n${JSON.stringify(response_json_schema)}`;
    }

    const groqRes = await fetch(GROQ_API_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!groqRes.ok) {
      const errText = await groqRes.text();
      return Response.json({ error: `Groq API error: ${groqRes.status} ${errText}` }, { status: 502 });
    }

    const data = await groqRes.json();
    const content = data.choices[0].message.content;

    if (response_json_schema) {
      try {
        const parsed = JSON.parse(content);
        return Response.json(parsed);
      } catch {
        return Response.json({ error: 'Model did not return valid JSON', raw: content }, { status: 502 });
      }
    }

    return Response.json({ result: content });
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }
});

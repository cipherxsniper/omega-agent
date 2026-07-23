// Minimal localStorage-backed replacement for base44.entities

const readAll = (name) => {
  try {
    return JSON.parse(localStorage.getItem(`omega_${name}`) || "[]");
  } catch {
    return [];
  }
};

const writeAll = (name, arr) => {
  localStorage.setItem(`omega_${name}`, JSON.stringify(arr));
};

const uid = () => Math.random().toString(36).slice(2) + Date.now().toString(36);

const makeEntity = (name) => ({
  list: async (sort, limit) => {
    let items = readAll(name);
    if (sort) {
      const desc = sort.startsWith("-");
      const key = desc ? sort.slice(1) : sort;
      items = [...items].sort((a, b) => {
        const av = a[key], bv = b[key];
        if (av === bv) return 0;
        return desc ? (av < bv ? 1 : -1) : (av > bv ? 1 : -1);
      });
    }
    return limit ? items.slice(0, limit) : items;
  },
  filter: async (query = {}, sort, limit) => {
    let items = readAll(name).filter((item) =>
      Object.entries(query).every(([k, v]) => item[k] === v)
    );
    if (sort) {
      const desc = sort.startsWith("-");
      const key = desc ? sort.slice(1) : sort;
      items = [...items].sort((a, b) => {
        const av = a[key], bv = b[key];
        if (av === bv) return 0;
        return desc ? (av < bv ? 1 : -1) : (av > bv ? 1 : -1);
      });
    }
    return limit ? items.slice(0, limit) : items;
  },
  create: async (data) => {
    const items = readAll(name);
    const record = { id: uid(), created_date: new Date().toISOString(), ...data };
    items.push(record);
    writeAll(name, items);
    return record;
  },
  bulkCreate: async (dataArr) => {
    const items = readAll(name);
    const created = dataArr.map((data) => ({
      id: uid(),
      created_date: new Date().toISOString(),
      ...data,
    }));
    writeAll(name, [...items, ...created]);
    return created;
  },
  update: async (id, updates) => {
    const items = readAll(name);
    const idx = items.findIndex((i) => i.id === id);
    if (idx === -1) throw new Error(`${name} record not found: ${id}`);
    items[idx] = { ...items[idx], ...updates };
    writeAll(name, items);
    return items[idx];
  },
  delete: async (id) => {
    const items = readAll(name).filter((i) => i.id !== id);
    writeAll(name, items);
    return { success: true };
  },
  subscribe: (callback) => {
    // no realtime backend in local mode; no-op unsubscribe
    return () => {};
  },
});

export const entities = new Proxy({}, {
  get: (_target, name) => makeEntity(name),
});

export const functions = {
  invoke: async (fnName) => {
    console.warn(`[local mode] functions.invoke("${fnName}") skipped — no backend connected.`);
    return { data: { error: `Function "${fnName}" is not available in local mode.` } };
  },
};

// --- Direct Groq API call, replacing the old base44 backend function ---
const GROQ_API_KEY = import.meta.env.VITE_GROQ_API_KEY;
const GROQ_MODEL = "llama-3.3-70b-versatile";

const callGroqComplete = async ({ prompt, response_json_schema, add_context_from_internet }) => {
  if (!GROQ_API_KEY) {
    return { data: { error: "Missing VITE_GROQ_API_KEY in .env.local" } };
  }

  if (add_context_from_internet) {
    console.warn("[local mode] add_context_from_internet is not supported — Groq direct calls have no web access.");
  }

  let systemPrompt = "You are a helpful assistant.";
  if (response_json_schema) {
    systemPrompt += ` Respond ONLY with valid JSON matching this schema, no markdown fences, no extra text: ${JSON.stringify(response_json_schema)}`;
  }

  const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${GROQ_API_KEY}`,
    },
    body: JSON.stringify({
      model: GROQ_MODEL,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: prompt },
      ],
      ...(response_json_schema ? { response_format: { type: "json_object" } } : {}),
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    return { data: { error: `Groq API error: ${err}` } };
  }

  const json = await res.json();
  const content = json.choices?.[0]?.message?.content || "";

  if (response_json_schema) {
    try {
      return { data: JSON.parse(content) };
    } catch {
      return { data: { error: "Failed to parse JSON from model output", raw: content } };
    }
  }

  return { data: { result: content.trim() } };
};

functions.invoke = async (fnName, payload) => {
  if (fnName === "groqComplete") {
    return callGroqComplete(payload || {});
  }
  console.warn(`[local mode] functions.invoke("${fnName}") skipped — no backend connected.`);
  return { data: { error: `Function "${fnName}" is not available in local mode.` } };
};

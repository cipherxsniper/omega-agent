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

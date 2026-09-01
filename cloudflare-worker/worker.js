// ═══════════════════════════════════════════════════════
//  Quản Lý Khách Hàng – Cloudflare Worker API
//  KV binding name: KV  (set in wrangler.toml)
// ═══════════════════════════════════════════════════════

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Content-Type': 'application/json; charset=utf-8',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: CORS });
}

async function getAll(env) {
  const raw = await env.KV.get('customers');
  return JSON.parse(raw || '[]');
}

async function saveAll(env, customers) {
  await env.KV.put('customers', JSON.stringify(customers));
}

export default {
  async fetch(request, env) {
    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS });
    }

    const url  = new URL(request.url);
    const path = url.pathname.replace(/\/$/, '');
    const id   = path.startsWith('/customers/') ? path.split('/')[2] : null;

    try {
      // ── GET /customers ────────────────────────────────────
      if (request.method === 'GET' && path === '/customers') {
        const customers = await getAll(env);
        return json(customers);
      }

      // ── POST /customers ───────────────────────────────────
      if (request.method === 'POST' && path === '/customers') {
        const customer  = await request.json();
        const customers = await getAll(env);
        // Use client-supplied id (Swift UUID) or generate one
        if (!customer.id) customer.id = crypto.randomUUID();
        if (!customer.createdAt) customer.createdAt = new Date().toISOString();
        customers.push(customer);
        await saveAll(env, customers);
        return json(customer, 201);
      }

      // ── PUT /customers/:id ────────────────────────────────
      if (request.method === 'PUT' && id) {
        const updated   = await request.json();
        const customers = await getAll(env);
        const idx = customers.findIndex(
          c => c.id?.toLowerCase() === id.toLowerCase()
        );
        if (idx === -1) return json({ error: 'Not found' }, 404);
        customers[idx] = { ...customers[idx], ...updated };
        await saveAll(env, customers);
        return json(customers[idx]);
      }

      // ── DELETE /customers/:id ─────────────────────────────
      if (request.method === 'DELETE' && id) {
        const customers = await getAll(env);
        const filtered  = customers.filter(
          c => c.id?.toLowerCase() !== id.toLowerCase()
        );
        await saveAll(env, filtered);
        return json({ ok: true, deleted: customers.length - filtered.length });
      }

      // ── Health check ──────────────────────────────────────
      if (path === '/' || path === '/health') {
        return json({ status: 'ok', app: 'Quản Lý Khách Hàng API' });
      }

      return json({ error: 'Not found' }, 404);

    } catch (err) {
      return json({ error: err.message }, 500);
    }
  },
};

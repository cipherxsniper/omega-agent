import { createClientFromRequest } from 'npm:@base44/sdk@0.8.40';

Deno.serve(async (req) => {
  try {
    const base44 = createClientFromRequest(req);
    const user = await base44.auth.me();
    if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

    const body = await req.json();
    const action = body.action;

    const { accessToken } = await base44.asServiceRole.connectors.getConnection('gmail');
    if (!accessToken) return Response.json({ error: 'Gmail not connected' }, { status: 403 });

    const authHeader = { Authorization: `Bearer ${accessToken}` };

    if (action === 'list') {
      const max = Math.min(body.max || 10, 50);
      const q = body.query || 'in:inbox newer_than:7d';
      const res = await fetch(
        `https://gmail.googleapis.com/gmail/v1/users/me/messages?q=${encodeURIComponent(q)}&maxResults=${max}`,
        { headers: authHeader }
      );
      if (!res.ok) {
        const err = await res.text();
        return Response.json({ error: `Gmail API error: ${res.status}`, details: err }, { status: res.status });
      }
      const data = await res.json();
      const messages = [];
      for (const msg of (data.messages || [])) {
        const detailRes = await fetch(
          `https://gmail.googleapis.com/gmail/v1/users/me/messages/${msg.id}?format=metadata&metadataHeaders=Subject&metadataHeaders=From&metadataHeaders=Date`,
          { headers: authHeader }
        );
        if (!detailRes.ok) continue;
        const detail = await detailRes.json();
        const headers = detail.payload?.headers || [];
        const subject = headers.find(h => h.name === 'Subject')?.value || '(no subject)';
        const from = headers.find(h => h.name === 'From')?.value || '';
        const date = headers.find(h => h.name === 'Date')?.value || '';
        messages.push({ id: msg.id, subject, from, date, snippet: detail.snippet || '' });
      }
      return Response.json({ messages });
    }

    if (action === 'get') {
      const messageId = body.messageId;
      if (!messageId) return Response.json({ error: 'messageId required' }, { status: 400 });
      const res = await fetch(
        `https://gmail.googleapis.com/gmail/v1/users/me/messages/${messageId}?format=full`,
        { headers: authHeader }
      );
      if (!res.ok) {
        return Response.json({ error: `Gmail API error: ${res.status}` }, { status: res.status });
      }
      const message = await res.json();
      const headers = message.payload?.headers || [];
      const subject = headers.find(h => h.name === 'Subject')?.value || '';
      const from = headers.find(h => h.name === 'From')?.value || '';
      const to = headers.find(h => h.name === 'To')?.value || '';
      const date = headers.find(h => h.name === 'Date')?.value || '';
      let bodyText = '';
      if (message.payload?.body?.data) {
        bodyText = atob(message.payload.body.data.replace(/-/g, '+').replace(/_/g, '/'));
      } else if (message.payload?.parts) {
        const textPart = message.payload.parts.find(p => p.mimeType === 'text/plain');
        if (textPart?.body?.data) {
          bodyText = atob(textPart.body.data.replace(/-/g, '+').replace(/_/g, '/'));
        }
      }
      return Response.json({ id: message.id, subject, from, to, date, body: bodyText, snippet: message.snippet });
    }

    if (action === 'send') {
      const to = body.to;
      const subject = body.subject;
      const text = body.text;
      if (!to || !subject || !text) {
        return Response.json({ error: 'to, subject, text required' }, { status: 400 });
      }
      const mimeMessage = [
        `To: ${to}`,
        `Subject: ${subject}`,
        'Content-Type: text/plain; charset=UTF-8',
        'MIME-Version: 1.0',
        '',
        text
      ].join('\r\n');
      const encodedMessage = btoa(mimeMessage).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
      const res = await fetch(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
        {
          method: 'POST',
          headers: { ...authHeader, 'Content-Type': 'application/json' },
          body: JSON.stringify({ raw: encodedMessage })
        }
      );
      if (!res.ok) {
        const err = await res.text();
        return Response.json({ error: `Gmail send error: ${res.status}`, details: err }, { status: res.status });
      }
      const result = await res.json();
      return Response.json({ success: true, messageId: result.id });
    }

    return Response.json({ error: 'Unknown action. Use: list, get, send' }, { status: 400 });
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }
});
import { createClientFromRequest } from 'npm:@base44/sdk@0.8.40';

Deno.serve(async (req) => {
  try {
    const base44 = createClientFromRequest(req);
    const user = await base44.auth.me();
    if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

    const body = await req.json();
    const action = body.action;

    // INGEST: store a new event and find correlations
    if (action === 'ingest') {
      const { source, sourceId, title, bodyText, url, metadata } = body;
      if (!source || !title) return Response.json({ error: 'source and title required' }, { status: 400 });

      // Dedupe check — skip if source + sourceId already exists
      const existing = await base44.asServiceRole.entities.Event.filter({ source, source_id: sourceId }, '-created_date', 1);
      if (existing.length > 0) {
        return Response.json({ status: 'duplicate', eventId: existing[0].id });
      }

      // Create the event
      const event = await base44.asServiceRole.entities.Event.create({
        source,
        source_id: sourceId || '',
        title,
        body: bodyText || '',
        url: url || '',
        metadata: metadata || {},
        correlation_status: 'none',
        processed: false,
      });

      // Find recent events for correlation (last 50, excluding self)
      const recent = await base44.asServiceRole.entities.Event.filter({}, '-created_date', 50);
      const candidates = recent.filter(e => e.id !== event.id);

      if (candidates.length === 0) {
        await base44.asServiceRole.entities.Event.update(event.id, { processed: true });
        return Response.json({ status: 'created', eventId: event.id, correlations: [] });
      }

      // Use LLM to compute semantic similarity between the new event and candidates
      const candidateSummaries = candidates.map(c => ({
        id: c.id,
        text: `${c.title} ${c.body || ''}`.substring(0, 200)
      }));

      const llmResponse = await base44.asServiceRole.integrations.Core.InvokeLLM({
        prompt: `You are a correlation engine. Compare this NEW event against a list of EXISTING events. For each, output a similarity score from 0.0 to 1.0 based on semantic relatedness (same topic, same project, same people, cause-effect, etc.).

NEW EVENT: ${title} ${bodyText || ''}

EXISTING EVENTS:
${candidateSummaries.map((c, i) => `[${i}] id=${c.id}: ${c.text}`).join('\n')}

Return JSON with a "scores" array, each item having "id" and "score" (0.0-1.0). Only include scores above 0.5.`,
        response_json_schema: {
          type: "object",
          properties: {
            scores: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  id: { type: "string" },
                  score: { type: "number" }
                }
              }
            }
          }
        }
      });

      const scores = llmResponse.scores || [];
      const autoLinked = scores.filter(s => s.score >= 0.8);
      const possiblyRelated = scores.filter(s => s.score >= 0.6 && s.score < 0.8);

      const relatedIds = scores.map(s => s.id);
      const bestScore = scores.length > 0 ? Math.max(...scores.map(s => s.score)) : 0;
      const correlationStatus = autoLinked.length > 0 ? 'auto_linked' : possiblyRelated.length > 0 ? 'possibly_related' : 'none';

      await base44.asServiceRole.entities.Event.update(event.id, {
        related_event_ids: relatedIds,
        correlation_score: bestScore,
        correlation_status: correlationStatus,
        processed: true,
      });

      return Response.json({
        status: 'created',
        eventId: event.id,
        correlations: scores,
        autoLinked: autoLinked.length,
        possiblyRelated: possiblyRelated.length,
      });
    }

    // QUERY: get events with their correlations
    if (action === 'query') {
      const source = body.source;
      const filter = source && source !== 'all' ? { source } : {};
      const events = await base44.asServiceRole.entities.Event.filter(filter, '-created_date', body.limit || 50);
      return Response.json({ events });
    }

    // CONFIRM: user confirms a possibly_related correlation
    if (action === 'confirm') {
      const eventId = body.eventId;
      const relatedId = body.relatedId;
      const event = await base44.asServiceRole.entities.Event.get(eventId);
      const related = [...(event.related_event_ids || []), relatedId];
      await base44.asServiceRole.entities.Event.update(eventId, {
        related_event_ids: related,
        correlation_status: 'confirmed'
      });
      return Response.json({ status: 'confirmed' });
    }

    return Response.json({ error: 'Unknown action. Use: ingest, query, confirm' }, { status: 400 });
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }
});
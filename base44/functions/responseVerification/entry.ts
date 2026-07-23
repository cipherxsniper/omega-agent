import { createClientFromRequest } from 'npm:@base44/sdk@0.8.40';

Deno.serve(async (req) => {
  try {
    const base44 = createClientFromRequest(req);
    const user = await base44.auth.me();
    if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

    const body = await req.json();
    const { request, response, reasoningChain, context } = body;

    if (!request || !response) {
      return Response.json({ error: 'request and response required' }, { status: 400 });
    }

    // PROACTIVE VERIFICATION: audit the reasoning chain for logical fallacies or incomplete data
    const verification = await base44.asServiceRole.integrations.Core.InvokeLLM({
      prompt: `You are a strict response verification engine. Audit this AI response before it is sent to the user.

ORIGINAL REQUEST:
${request}

RESPONSE:
${response}

REASONING CHAIN:
${reasoningChain || '(none provided)'}

CONTEXT/TOOL OUTPUT AVAILABLE:
${context || '(none)'}

Verify the following and return a JSON object:
1. "claims_verified": boolean — does every factual claim in the response trace to context or tool output?
2. "reasoning_valid": boolean — does each reasoning step follow logically from the last, with assumptions stated?
3. "completeness": boolean — does the response cover everything the user asked for?
4. "issues": array of strings — specific problems found (empty if none)
5. "revised_response": string — if any check failed, provide the corrected response. If all pass, return the original response unchanged.
6. "passed": boolean — true only if all three checks pass

Be rigorous. Do not let anything slide. If you find a problem, fix it in revised_response rather than appending a caveat.`,
      response_json_schema: {
        type: "object",
        properties: {
          claims_verified: { type: "boolean" },
          reasoning_valid: { type: "boolean" },
          completeness: { type: "boolean" },
          issues: { type: "array", items: { "type": "string" } },
          revised_response: { type: "string" },
          passed: { type: "boolean" }
        }
      }
    });

    return Response.json({
      passed: verification.passed,
      claims_verified: verification.claims_verified,
      reasoning_valid: verification.reasoning_valid,
      completeness: verification.completeness,
      issues: verification.issues || [],
      finalResponse: verification.passed ? response : verification.revised_response,
      wasRevised: !verification.passed,
    });
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }
});
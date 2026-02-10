/**
 * a0x_knowledge_propose — Propose a solution to the collective brain
 *
 * After fixing a bug, solving a compilation error, discovering a pattern, or
 * finding a workaround: propose it so no other agent repeats your mistake.
 */

import { Type } from "@sinclair/typebox";
import type { A0xMcpClient } from "../mcp-client.js";
import type { BrainState } from "../types.js";

export const knowledgeProposeSchema = Type.Object({
  memory_type: Type.Union(
    [
      Type.Literal("pattern"),
      Type.Literal("error"),
      Type.Literal("success"),
      Type.Literal("anti-pattern"),
      Type.Literal("insight"),
    ],
    {
      description:
        "Type of knowledge: pattern (repeatable approach), error (mistake to avoid), success (something that worked), anti-pattern (approach to avoid), insight (general observation).",
    },
  ),
  situation: Type.String({
    description:
      "When does this apply? Be specific enough that another agent would know exactly when this is relevant.",
  }),
  action: Type.String({
    description:
      "What to do. Be actionable enough that another agent could follow these steps without guessing.",
  }),
  outcome: Type.String({
    description:
      "Expected result. Be measurable so another agent knows if it worked.",
  }),
  learnings: Type.Array(Type.String(), {
    description: "Key takeaways — array of concise lessons learned.",
  }),
  tags: Type.Array(Type.String(), {
    description:
      "Searchable tags for discoverability (e.g. ['base', 'gas', 'estimation', 'L2']).",
  }),
});

export function createKnowledgeProposeTool(
  client: A0xMcpClient,
  state: BrainState
) {
  return {
    name: "a0x_knowledge_propose",
    description: "Propose new knowledge to the collective brain after solving a problem",
    parameters: knowledgeProposeSchema,
    async execute(toolCallId: string, params: Record<string, unknown>) {
      try {
        const result = await client.callTool("knowledge/propose", params);

        // Increment counter
        state.proposeCount++;

        const text = `✅ Proposal submitted!\n\n` +
          `**Proposal ID:** ${result.proposal_id}\n` +
          `**Status:** ${result.status}\n` +
          `**Votes needed:** ${result.votes_required}\n` +
          `**Next:** ${result.next_steps}\n`;

        return {
          content: [{ type: "text", text }],
          details: result
        };
      } catch (err) {
        return {
          content: [{ type: "text", text: `Error proposing knowledge: ${err instanceof Error ? err.message : String(err)}` }],
          error: true
        };
      }
    }
  };
}

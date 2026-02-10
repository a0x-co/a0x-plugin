/**
 * a0x_knowledge_vote — Vote on pending proposals
 *
 * When you see pending proposals from other agents during a search, vote on
 * them to help curate the collective brain. Only verified agents can vote.
 */

import { Type } from "@sinclair/typebox";
import type { A0xMcpClient } from "../mcp-client.js";
import type { BrainState } from "../types.js";

export const knowledgeVoteSchema = Type.Object({
  proposalId: Type.String({
    description: "The ID of the proposal to vote on.",
  }),
  vote: Type.Union([Type.Literal("positive"), Type.Literal("negative")], {
    description:
      "Your vote. Positive if the proposal is clear, specific, and useful. Negative if vague or incorrect.",
  }),
  reason: Type.Optional(
    Type.String({
      description:
        "Required for negative votes. Explain why the proposal should be rejected.",
    }),
  ),
});

export function createKnowledgeVoteTool(
  client: A0xMcpClient,
  state: BrainState
) {
  return {
    name: "a0x_knowledge_vote",
    description: "Vote on pending proposals in the collective brain",
    parameters: knowledgeVoteSchema,
    async execute(toolCallId: string, params: Record<string, unknown>) {
      // Validate: negative votes require reason
      if (params.vote === "negative" && !params.reason) {
        return {
          content: [{ type: "text", text: "❌ Error: Negative votes require a reason explaining why the proposal is not useful." }],
          error: true
        };
      }

      try {
        const result = await client.callTool("knowledge/vote", params);

        // Increment counter
        state.voteCount++;

        const text = `✅ Vote recorded!\n\n` +
          `**Proposal:** ${result.proposal_id}\n` +
          `**Status:** ${result.current_status}\n` +
          `**Votes:** ${result.votes_positive} positive, ${result.votes_negative} negative\n` +
          `**Required:** ${result.votes_required}\n`;

        return {
          content: [{ type: "text", text }],
          details: result
        };
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : String(err);
        let text = `❌ Error voting: ${errMsg}\n`;

        // Friendly error messages
        if (errMsg.includes("403") || errMsg.includes("not verified")) {
          text += "\nNote: You need at least one approved proposal to vote.";
        } else if (errMsg.includes("409") || errMsg.includes("already voted")) {
          text += "\nNote: You already voted on this proposal.";
        }

        return {
          content: [{ type: "text", text }],
          error: true
        };
      }
    }
  };
}

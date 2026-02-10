/**
 * a0x_knowledge_my_proposals — Check status of your proposals
 *
 * See which of your proposals are pending, approved, or rejected.
 * Useful for tracking your contributions and learning from feedback.
 */

import { Type } from "@sinclair/typebox";
import type { A0xMcpClient } from "../mcp-client.js";

export const knowledgeMyProposalsSchema = Type.Object({});

export function createKnowledgeMyProposalsTool(client: A0xMcpClient) {
  return {
    name: "a0x_knowledge_my_proposals",
    description: "Check the status of your knowledge proposals (pending, approved, rejected)",
    parameters: knowledgeMyProposalsSchema,
    async execute(toolCallId: string, params: Record<string, unknown>) {
      try {
        const result = await client.callTool("knowledge/my-proposals", {});
        const text = result.content?.map((c: any) => c.text).join("\n") || "No proposals found.";
        return {
          content: [{ type: "text", text }],
          details: result
        };
      } catch (err) {
        return {
          content: [{ type: "text", text: `Error checking proposals: ${err instanceof Error ? err.message : String(err)}` }],
          error: true
        };
      }
    }
  };
}

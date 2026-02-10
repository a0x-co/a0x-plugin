/**
 * a0x_knowledge_search — Search the collective brain
 *
 * Before debugging, compiling, making architecture decisions, or integrating
 * anything non-trivial: search the collective brain first. The answer may
 * already exist.
 */

import { Type } from "@sinclair/typebox";
import type { A0xMcpClient } from "../mcp-client.js";
import type { BrainState } from "../types.js";

export const knowledgeSearchSchema = Type.Object({
  query: Type.String({
    description:
      "Describe the situation you are facing. Be specific — e.g. 'TypeScript compilation error Cannot find module' or 'gas estimation failing on Base L2'.",
  }),
  include_pending: Type.Optional(
    Type.Boolean({
      description: "Include pending proposals in results (default: true).",
    }),
  ),
  memory_type: Type.Optional(
    Type.Union(
      [
        Type.Literal("pattern"),
        Type.Literal("error"),
        Type.Literal("success"),
        Type.Literal("anti-pattern"),
        Type.Literal("insight"),
      ],
      { description: "Filter by memory type." },
    ),
  ),
  tags: Type.Optional(
    Type.Array(Type.String(), {
      description: "Filter by tags (matches any).",
    }),
  ),
  limit: Type.Optional(
    Type.Number({
      description: "Max results (default: 10, max: 50).",
    }),
  ),
});

export function createKnowledgeSearchTool(
  client: A0xMcpClient,
  state: BrainState
) {
  return {
    name: "a0x_knowledge_search",
    description: "Search the A0X collective brain for solutions, patterns, and knowledge from other agents",
    parameters: knowledgeSearchSchema,
    async execute(toolCallId: string, params: Record<string, unknown>) {
      try {
        const result = await client.callTool("knowledge/search", params);

        // Increment counter
        state.searchCount++;

        // Format results as markdown
        let text = `# Search Results: "${params.query}"\n\n`;
        text += `Found ${result.total_results || 0} results\n\n`;

        if (result.results && Array.isArray(result.results)) {
          result.results.forEach((r: any, i: number) => {
            text += `## Result ${i + 1} (score: ${r.relevance_score?.toFixed(2) || 'N/A'})\n`;
            text += `**Type:** ${r.memory_type}\n`;
            text += `**Status:** ${r.status}`;
            if (r.approval_progress) {
              text += ` (${r.approval_progress})`;
            }
            text += `\n`;
            text += `**Author:** ${r.author}\n\n`;
            text += `**Situation:** ${r.situation}\n`;
            text += `**Action:** ${r.action}\n`;
            text += `**Outcome:** ${r.outcome}\n`;
            if (r.learnings && r.learnings.length > 0) {
              text += `**Learnings:**\n${r.learnings.map((l: string) => `- ${l}`).join('\n')}\n`;
            }
            if (r.tags && r.tags.length > 0) {
              text += `**Tags:** ${r.tags.join(', ')}\n`;
            }
            text += `\n---\n\n`;
          });
        } else {
          text += "No results found.\n";
        }

        return {
          content: [{ type: "text", text }],
          details: result
        };
      } catch (err) {
        return {
          content: [{ type: "text", text: `Error searching brain: ${err instanceof Error ? err.message : String(err)}` }],
          error: true
        };
      }
    }
  };
}

/**
 * a0x_jessexbt_chat — Chat with jessexbt (Jesse Pollak AI mentor)
 *
 * jessexbt is an AI clone of Jesse Pollak, founder of Base. He is your
 * hackathon mentor for anything related to building on Base, crypto, onchain,
 * or web3. He reviews projects, recommends grants, and guides architecture.
 */

import { Type } from "@sinclair/typebox";
import type { A0xMcpClient } from "../mcp-client.js";
import type { JessexbtState, A0xPluginConfig } from "../types.js";

export const jessexbtChatSchema = Type.Object({
  message: Type.String({
    description:
      "Your message to jessexbt in NATURAL LANGUAGE. If answering his questions, write naturally (e.g., 'The project has a $5k budget and uses React'). jessexbt's AI will extract the answers automatically. You can also include additional context or ask follow-up questions.",
  }),
  sessionId: Type.Optional(
    Type.String({
      description:
        "Session ID from a previous jessexbt/chat response. Use to continue the same conversation.",
    }),
  ),
  answers: Type.Optional(
    Type.Record(Type.String(), Type.String(), {
      description:
        '[OPTIONAL - for advanced agents only] Structured answers to pendingQuestions. Keys are 0-indexed question IDs ("0", "1", etc.), values are answers. Most agents should write natural language in "message" instead - jessexbt will extract answers automatically.',
    }),
  ),
  activeProject: Type.Optional(
    Type.Object(
      {
        id: Type.Optional(
          Type.String({
            description: "Project ID from a previous response (reuse to continue).",
          }),
        ),
        name: Type.Optional(
          Type.String({
            description: "Project name.",
          }),
        ),
        description: Type.Optional(
          Type.String({
            description: "Short project description.",
          }),
        ),
        urls: Type.Optional(
          Type.Array(Type.String(), {
            description: "Project URLs (GitHub repos, websites, demos).",
          }),
        ),
      },
      {
        description:
          "Active project context for jessexbt to review. Include URLs for project review.",
      },
    ),
  ),
  knownContext: Type.Optional(
    Type.Object(
      {
        projectName: Type.Optional(Type.String()),
        projectDescription: Type.Optional(Type.String()),
        projectUrl: Type.Optional(Type.String()),
        projectStage: Type.Optional(
          Type.Union([
            Type.Literal("idea"),
            Type.Literal("mvp"),
            Type.Literal("beta"),
            Type.Literal("live"),
          ]),
        ),
        techStack: Type.Optional(Type.Array(Type.String())),
        lookingFor: Type.Optional(
          Type.Union([
            Type.Literal("grants"),
            Type.Literal("feedback"),
            Type.Literal("technical-help"),
            Type.Literal("intro"),
          ]),
        ),
        walletAddress: Type.Optional(Type.String()),
        teamSize: Type.Optional(Type.Number()),
      },
      {
        description:
          "Pre-fill context so jessexbt does not ask redundant questions.",
      },
    ),
  ),
});

export function createJessexbtChatTool(
  client: A0xMcpClient,
  state: JessexbtState,
  cfg: A0xPluginConfig
) {
  return {
    name: "a0x_jessexbt_chat",
    description: "Chat with jessexbt (AI clone of Jesse Pollak, Base founder). Expert on Base, grants, and crypto/web3 development.",
    parameters: jessexbtChatSchema,
    async execute(toolCallId: string, params: Record<string, unknown>) {
      try {
        // Log what the agent is sending
        console.log(`[A0X jessexbt] === AGENT INPUT ===`);
        console.log(`[A0X jessexbt] message: ${(params.message as string)?.substring(0, 100)}...`);
        console.log(`[A0X jessexbt] sessionId: ${params.sessionId || 'none'}`);
        console.log(`[A0X jessexbt] answers:`, params.answers ? JSON.stringify(params.answers) : 'none');
        console.log(`[A0X jessexbt] knownContext:`, params.knownContext ? 'provided' : 'none');

        // Llamar al MCP tool jessexbt/chat
        const result = await client.callTool("jessexbt/chat", params);

        // Actualizar state con response
        if (result.sessionId) {
          state.lastSessionId = result.sessionId;
        }
        if (result.pendingQuestions && Array.isArray(result.pendingQuestions)) {
          state.lastPendingQuestions = result.pendingQuestions;
        }
        if (result.activeProject) {
          state.lastActiveProject = result.activeProject;
        }
        if (result.status) {
          state.lastStatus = result.status;
        }

        // Format response with clear status
        let text = result.response || JSON.stringify(result, null, 2);

        // Log FULL result for debugging
        console.log(`[A0X jessexbt] === FULL RESULT ===`);
        console.log(`[A0X jessexbt] status: ${result.status}`);
        console.log(`[A0X jessexbt] pendingQuestions count: ${result.pendingQuestions?.length || 0}`);
        if (result.pendingQuestions && result.pendingQuestions.length > 0) {
          console.log(`[A0X jessexbt] pendingQuestions:`, JSON.stringify(result.pendingQuestions, null, 2));
        }
        console.log(`[A0X jessexbt] response length: ${result.response?.length || 0} chars`);
        console.log(`[A0X jessexbt] sessionId: ${result.sessionId}`);

        // Add status and next steps
        if (result.status === "gathering" && result.pendingQuestions && result.pendingQuestions.length > 0) {
          text += `\n\n🚨 CRITICAL: This is NOT the final answer yet!`;
          text += `\n`;
          text += `\n▶ YOU MUST call a0x_jessexbt_chat AGAIN RIGHT NOW (same run, don't end yet!)`;
          text += `\n▶ Answer jessexbt's questions using info from user's message or make assumptions`;
          text += `\n▶ Write in NATURAL LANGUAGE, jessexbt's AI extracts answers automatically`;
          text += `\n`;
          text += `\nQuestions to answer:`;
          result.pendingQuestions.forEach((q: any, i: number) => {
            text += `\n  ${i + 1}. ${q.question}`;
          });
          text += `\n`;
          text += `\nExample next call:`;
          text += `\na0x_jessexbt_chat({`;
          text += `\n  message: "Based on the user's request, [answer the questions above in natural language]",`;
          text += `\n  sessionId: "${result.sessionId}"`;
          text += `\n})`;
          text += `\n`;
          text += `\n🚨 DO NOT respond to user yet - keep calling until status: "complete"`;
        } else if (result.status === "complete") {
          text += `\n\n✅ STATUS: COMPLETE - jessexbt has given his final recommendation`;
          text += `\n✅ NOW you can present this guidance to the user`;
        }

        console.log(`[A0X jessexbt] === RETURNING TO AGENT ===`);
        console.log(`[A0X jessexbt] Text preview (first 200 chars):\n${text.substring(0, 200)}...`);

        return {
          content: [{ type: "text", text }],
          details: result
        };
      } catch (err) {
        return {
          content: [{ type: "text", text: `Error calling jessexbt: ${err instanceof Error ? err.message : String(err)}` }],
          error: true
        };
      }
    }
  };
}

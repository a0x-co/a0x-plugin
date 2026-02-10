/**
 * Shared types for the A0X OpenClaw plugin.
 */

/** Plugin configuration stored in openclaw.json under plugins.a0x.config */
export type A0xPluginConfig = {
  apiKey: string;
  agentName?: string;
  mcpEndpoint?: string;
  autoSearch?: boolean;
  maxJessexbtTurns?: number;
};

/** JSON-RPC 2.0 request body */
export type JsonRpcRequest = {
  jsonrpc: "2.0";
  id: number;
  method: string;
  params: Record<string, unknown>;
};

/** JSON-RPC 2.0 response body */
export type JsonRpcResponse = {
  jsonrpc: "2.0";
  id: number;
  result?: JsonRpcToolResult;
  error?: {
    code: number;
    message: string;
    data?: unknown;
  };
};

/** MCP tools/call result shape */
export type JsonRpcToolResult = {
  content?: Array<{ type: string; text: string }>;
  isError?: boolean;
  [key: string]: unknown;
};

/** Standard tool return shape for OpenClaw agent tools */
export type ToolResult = {
  content: Array<{ type: "text"; text: string }>;
  details?: unknown;
};

/** Shared jessexbt conversation state (reset per agent run) */
export interface JessexbtState {
  callCount: number;
  lastSessionId?: string;
  lastPendingQuestions: Array<{ id: string; question: string }>;
  lastActiveProject?: Record<string, unknown>;
  lastStatus?: "gathering" | "complete";
}

/** Shared collective brain state (reset per agent run) */
export interface BrainState {
  searchCount: number;
  proposeCount: number;
  voteCount: number;
}

/** Pending proposals tracking state */
export interface PendingProposalsState {
  lastSearchHadPending: boolean;
  lastSearchTime: number;
}

/** Default MCP endpoint */
export const DEFAULT_MCP_ENDPOINT =
  "https://mcp-agents.a0x.co";

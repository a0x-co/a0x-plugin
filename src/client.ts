/**
 * A0X MCP HTTP Client
 *
 * Makes JSON-RPC 2.0 POST requests to the A0X MCP endpoint.
 * Endpoint format: ${baseUrl}/${apiKey}/mcp
 */

import type { JsonRpcRequest, JsonRpcResponse, JsonRpcToolResult } from "./types.js";
import { DEFAULT_MCP_ENDPOINT } from "./types.js";

export type A0xClientOptions = {
  apiKey: string;
  endpoint?: string;
  timeoutMs?: number;
};

let requestId = 0;

function nextId(): number {
  requestId += 1;
  return requestId;
}

export class A0xMcpClient {
  private readonly apiKey: string;
  private readonly endpoint: string;
  private readonly timeoutMs: number;

  constructor(options: A0xClientOptions) {
    this.apiKey = options.apiKey;
    this.endpoint = options.endpoint ?? DEFAULT_MCP_ENDPOINT;
    this.timeoutMs = options.timeoutMs ?? 10_000;
  }

  /**
   * Build the full MCP URL with the API key in the path.
   */
  private get mcpUrl(): string {
    const base = this.endpoint.replace(/\/+$/, "");
    return `${base}/${this.apiKey}/mcp`;
  }

  /**
   * Call an MCP tool by name with the given arguments.
   */
  async callTool(
    toolName: string,
    args: Record<string, unknown>,
  ): Promise<JsonRpcToolResult> {
    const body: JsonRpcRequest = {
      jsonrpc: "2.0",
      id: nextId(),
      method: "tools/call",
      params: {
        name: toolName,
        arguments: args,
      },
    };

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);

    let response: Response;
    try {
      response = await fetch(this.mcpUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
        signal: controller.signal,
      });
    } catch (err) {
      clearTimeout(timer);
      if (err instanceof Error && err.name === "AbortError") {
        throw new A0xClientError(
          `Request to A0X MCP timed out after ${this.timeoutMs}ms`,
          "TIMEOUT",
        );
      }
      throw new A0xClientError(
        `Failed to connect to A0X MCP: ${err instanceof Error ? err.message : String(err)}`,
        "NETWORK",
      );
    } finally {
      clearTimeout(timer);
    }

    if (!response.ok) {
      const text = await response.text().catch(() => "");
      throw new A0xClientError(
        `A0X MCP returned HTTP ${response.status}: ${text || response.statusText}`,
        "HTTP",
        response.status,
      );
    }

    let json: JsonRpcResponse;
    try {
      json = (await response.json()) as JsonRpcResponse;
    } catch {
      throw new A0xClientError(
        "A0X MCP returned invalid JSON",
        "PARSE",
      );
    }

    if (json.error) {
      throw new A0xClientError(
        json.error.message || "Unknown MCP error",
        "RPC",
        json.error.code,
      );
    }

    return json.result ?? { content: [{ type: "text", text: "No result returned" }] };
  }
}

export class A0xClientError extends Error {
  readonly kind: "TIMEOUT" | "NETWORK" | "HTTP" | "PARSE" | "RPC";
  readonly statusCode?: number;

  constructor(message: string, kind: A0xClientError["kind"], statusCode?: number) {
    super(message);
    this.name = "A0xClientError";
    this.kind = kind;
    this.statusCode = statusCode;
  }
}

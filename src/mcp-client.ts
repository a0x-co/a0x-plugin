import type { PluginLogger } from "openclaw/plugin-sdk";

export interface McpToolCallParams {
  name: string;
  arguments: Record<string, unknown>;
}

export class A0xMcpClient {
  private sessionId?: string;
  private requestId = 1;
  private initialized = false;

  constructor(
    private baseUrl: string,
    private apiKey: string,
    private logger?: PluginLogger
  ) {}

  private async ensureInitialized(): Promise<void> {
    if (this.initialized) return;

    this.logger?.info("A0X: Initializing MCP session...");

    await this.callMcp({
      jsonrpc: "2.0",
      id: this.requestId++,
      method: "initialize"
    });

    this.initialized = true;
    this.logger?.info("A0X: MCP session initialized");
  }

  async callTool(name: string, args: Record<string, unknown>): Promise<any> {
    // Lazy initialization on first call
    await this.ensureInitialized();

    const result = await this.callMcp({
      jsonrpc: "2.0",
      id: this.requestId++,
      method: "tools/call",
      params: {
        name,
        arguments: args
      }
    });

    // Parse result
    if (result.content?.[0]?.text) {
      try {
        return JSON.parse(result.content[0].text);
      } catch {
        return result;
      }
    }

    return result;
  }

  private async callMcp(body: any): Promise<any> {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      "X-API-Key": this.apiKey
    };

    if (this.sessionId) {
      headers["Mcp-Session-Id"] = this.sessionId;
    }

    const res = await fetch(`${this.baseUrl}/mcp`, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(120000)  // 2 min timeout
    });

    // Guardar session ID del header
    const sessionHeader = res.headers.get("Mcp-Session-Id");
    if (sessionHeader) {
      this.sessionId = sessionHeader;
    }

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`MCP call failed: ${res.status} ${text}`);
    }

    const data = await res.json();

    // JSON-RPC error
    if (data.error) {
      throw new Error(`MCP error: ${data.error.message}`);
    }

    return data.result;
  }

  async cleanup(): Promise<void> {
    if (!this.sessionId) return;

    try {
      await fetch(`${this.baseUrl}/mcp`, {
        method: "DELETE",
        headers: {
          "Mcp-Session-Id": this.sessionId
        }
      });
      this.logger?.info("A0X: MCP session cleaned up");
    } catch (err) {
      this.logger?.warn(`A0X: Failed to cleanup session: ${err}`);
    }

    this.sessionId = undefined;
  }
}

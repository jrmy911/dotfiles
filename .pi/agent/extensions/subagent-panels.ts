import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

type PanelState = {
  id: string;
  agent: string;
  task?: string;
  status: "running" | "done" | "failed" | "unknown";
  model?: string;
  usage?: any;
  latest: string;
  tool?: string;
  updatedAt: number;
};

type ToolRun = {
  toolCallId: string;
  mode?: string;
  title: string;
  panels: PanelState[];
  updatedAt: number;
};

function textFromContent(content: any): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .map((p) => (p?.type === "text" ? p.text : ""))
    .filter(Boolean)
    .join("\n");
}

function finalAssistantText(messages: any[] | undefined): string {
  if (!Array.isArray(messages)) return "";
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    if (msg?.role !== "assistant" || !Array.isArray(msg.content)) continue;
    const text = textFromContent(msg.content).trim();
    if (text) return text;
  }
  return "";
}

function latestTool(messages: any[] | undefined): string | undefined {
  if (!Array.isArray(messages)) return undefined;
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    const parts = Array.isArray(msg?.content) ? msg.content : [];
    for (let j = parts.length - 1; j >= 0; j--) {
      const p = parts[j];
      if (p?.type === "toolCall") return String(p.name || p.toolName || "tool");
    }
  }
  return undefined;
}

function statusOf(result: any): PanelState["status"] {
  if (result?.exitCode === -1 || result?.status === "running" || result?.running === true) return "running";
  if (result?.exitCode && result.exitCode !== 0) return "failed";
  if (result?.stopReason === "error" || result?.stopReason === "aborted" || result?.errorMessage) return "failed";
  if (result?.exitCode === 0 || result?.status === "done" || result?.status === "complete" || result?.done === true) return "done";
  return "unknown";
}

function panelsFromDetails(details: any, fallbackText: string): PanelState[] {
  const raw = Array.isArray(details?.results)
    ? details.results
    : Array.isArray(details?.tasks)
      ? details.tasks
      : Array.isArray(details?.children)
        ? details.children
        : [];

  return raw.map((r: any, index: number) => {
    const latest =
      finalAssistantText(r?.messages) ||
      r?.errorMessage ||
      r?.stderr ||
      r?.output ||
      r?.latest ||
      (statusOf(r) === "running" ? "working..." : fallbackText) ||
      "";
    return {
      id: String(r?.id ?? r?.runId ?? `${r?.agent ?? "agent"}-${index}`),
      agent: String(r?.agent ?? r?.name ?? r?.label ?? `agent ${index + 1}`),
      task: r?.task,
      status: statusOf(r),
      model: r?.model,
      usage: r?.usage,
      latest,
      tool: latestTool(r?.messages),
      updatedAt: Date.now(),
    };
  });
}

function fit(line: string, width: number): string {
  return truncateToWidth(line, Math.max(0, width), "…");
}

function pad(line: string, width: number): string {
  const w = visibleWidth(line);
  return line + " ".repeat(Math.max(0, width - w));
}

function formatUsage(usage: any): string {
  if (!usage) return "";
  const parts: string[] = [];
  if (usage.turns) parts.push(`${usage.turns}t`);
  if (usage.input) parts.push(`↑${usage.input}`);
  if (usage.output) parts.push(`↓${usage.output}`);
  if (usage.cost) parts.push(`$${Number(usage.cost).toFixed(3)}`);
  return parts.join(" ");
}

function makeWidget(getRuns: () => ToolRun[]) {
  return (_tui: any, theme: any) => ({
    invalidate() {},
    render(width: number): string[] {
      const runs = getRuns();
      if (runs.length === 0) return [];
      const panels = runs.flatMap((r) => r.panels);
      if (panels.length === 0) return [];

      const cols = width >= 100 ? 2 : 1;
      const gap = cols === 2 ? 2 : 0;
      const panelWidth = Math.max(32, Math.floor((width - gap) / cols));
      const lines: string[] = [];
      const running = panels.filter((p) => p.status === "running").length;
      const done = panels.filter((p) => p.status === "done").length;
      const failed = panels.filter((p) => p.status === "failed").length;
      lines.push(
        fit(
          `${theme.fg("toolTitle", theme.bold("subagents"))} ${theme.fg("success", `✓ ${done}`)} ${theme.fg("warning", `● ${running}`)} ${failed ? theme.fg("error", `✗ ${failed}`) : ""}`,
          width,
        ),
      );

      const rendered = panels.map((p) => {
        const color = p.status === "done" ? "success" : p.status === "failed" ? "error" : p.status === "running" ? "accent" : "muted";
        const icon = p.status === "done" ? "✓" : p.status === "failed" ? "✗" : p.status === "running" ? "●" : "○";
        const header = `${theme.fg(color, icon)} ${theme.fg("accent", theme.bold(p.agent))}${p.model ? theme.fg("dim", ` · ${p.model}`) : ""}`;
        const meta = [p.tool ? `🔧 ${p.tool}` : "", formatUsage(p.usage)].filter(Boolean).join(" · ");
        const body = (p.latest || p.task || "").replace(/\s+/g, " ").trim();
        return [
          theme.fg("borderMuted", "┌" + "─".repeat(panelWidth - 2) + "┐"),
          theme.fg("borderMuted", "│") + pad(fit(" " + header, panelWidth - 2), panelWidth - 2) + theme.fg("borderMuted", "│"),
          theme.fg("borderMuted", "│") + pad(fit(" " + (meta || p.status), panelWidth - 2), panelWidth - 2) + theme.fg("borderMuted", "│"),
          theme.fg("borderMuted", "│") + pad(fit(" " + body, panelWidth - 2), panelWidth - 2) + theme.fg("borderMuted", "│"),
          theme.fg("borderMuted", "└" + "─".repeat(panelWidth - 2) + "┘"),
        ];
      });

      for (let i = 0; i < rendered.length; i += cols) {
        const left = rendered[i];
        const right = cols === 2 ? rendered[i + 1] : undefined;
        for (let row = 0; row < 5; row++) {
          if (right) lines.push(pad(left[row], panelWidth) + "  " + pad(right[row], panelWidth));
          else lines.push(fit(left[row], width));
        }
      }
      return lines.slice(0, Math.max(1, Math.min(30, lines.length)));
    },
  });
}

export default function (pi: ExtensionAPI) {
  const runs = new Map<string, ToolRun>();
  let enabled = true;
  let lastCtx: any;

  const refresh = (ctx: any) => {
    lastCtx = ctx;
    if (!enabled || runs.size === 0) ctx.ui.setWidget("subagent-panels", undefined);
    else ctx.ui.setWidget("subagent-panels", makeWidget(() => Array.from(runs.values())), { placement: "aboveEditor" });
  };

  pi.registerCommand("subagent-panels", {
    description: "Toggle live subagent panel widget",
    handler: async (args, ctx) => {
      const value = args.trim().toLowerCase();
      enabled = value === "on" ? true : value === "off" ? false : !enabled;
      refresh(ctx);
      ctx.ui.notify(`Subagent panels ${enabled ? "enabled" : "disabled"}`, "info");
    },
  });

  pi.on("tool_execution_update", (event: any, ctx) => {
    if (!String(event.toolName).includes("subagent")) return;
    const result = event.partialResult ?? event.result ?? {};
    const details = result.details;
    const text = textFromContent(result.content);
    const panels = panelsFromDetails(details, text);
    if (panels.length === 0) return;
    runs.set(event.toolCallId, {
      toolCallId: event.toolCallId,
      mode: details?.mode,
      title: String(event.toolName),
      panels,
      updatedAt: Date.now(),
    });
    refresh(ctx);
  });

  pi.on("tool_execution_end", (event: any, ctx) => {
    if (!String(event.toolName).includes("subagent")) return;
    const result = event.result ?? {};
    const panels = panelsFromDetails(result.details, textFromContent(result.content));
    if (panels.length > 0) {
      runs.set(event.toolCallId, { toolCallId: event.toolCallId, mode: result.details?.mode, title: String(event.toolName), panels, updatedAt: Date.now() });
      refresh(ctx);
      setTimeout(() => {
        runs.delete(event.toolCallId);
        if (lastCtx) refresh(lastCtx);
      }, 4000);
    } else {
      runs.delete(event.toolCallId);
      refresh(ctx);
    }
  });

  pi.on("session_shutdown", (_event, ctx) => {
    runs.clear();
    ctx.ui.setWidget("subagent-panels", undefined);
  });
}

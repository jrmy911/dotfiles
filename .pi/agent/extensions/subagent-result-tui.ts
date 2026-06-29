import { getMarkdownTheme, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Key, Markdown, matchesKey, truncateToWidth } from "@earendil-works/pi-tui";

const SLASH_RESULT_TYPE = "subagent-slash-result";

type SlashDetails = {
	requestId?: string;
	result?: {
		content?: Array<{ type?: string; text?: string }>;
		details?: {
			mode?: string;
			results?: Array<{
				agent?: string;
				task?: string;
				exitCode?: number;
				error?: string;
				messages?: unknown[];
				progress?: { status?: string; durationMs?: number };
			}>;
		};
	};
};

function textFromContent(content: unknown): string {
	if (!Array.isArray(content)) return "";
	return content
		.map((part) => (part && typeof part === "object" && "text" in part ? String((part as { text?: unknown }).text ?? "") : ""))
		.filter(Boolean)
		.join("\n\n");
}

function getAssistantText(messages: unknown[] | undefined): string {
	if (!Array.isArray(messages)) return "";
	for (let i = messages.length - 1; i >= 0; i--) {
		const message = messages[i];
		if (!message || typeof message !== "object") continue;
		const role = "role" in message ? (message as { role?: unknown }).role : undefined;
		if (role !== "assistant") continue;
		const content = (message as { content?: unknown }).content;
		if (typeof content === "string") return content;
		if (Array.isArray(content)) {
			const text = content
				.map((part) => {
					if (typeof part === "string") return part;
					if (part && typeof part === "object" && "text" in part) return String((part as { text?: unknown }).text ?? "");
					return "";
				})
				.filter(Boolean)
				.join("\n\n");
			if (text.trim()) return text;
		}
	}
	return "";
}

function buildMarkdown(details: SlashDetails): string {
	const result = details.result;
	const runDetails = result?.details;
	const results = runDetails?.results ?? [];
	const mode = runDetails?.mode ?? (results.length > 1 ? "parallel" : "single");
	const lines: string[] = [];

	lines.push(`# Subagent result`);
	lines.push("");
	lines.push(`Mode: \`${mode}\``);
	if (details.requestId) lines.push(`Request: \`${details.requestId}\``);
	lines.push("");

	if (results.length > 0) {
		lines.push("## Runs");
		lines.push("");
		for (const [index, item] of results.entries()) {
			const agent = item.agent ?? `agent-${index + 1}`;
			const status = item.error ? "failed" : item.progress?.status ?? (item.exitCode === 0 ? "complete" : "unknown");
			lines.push(`### ${agent}`);
			lines.push("");
			lines.push(`- Status: \`${status}\``);
			if (typeof item.exitCode === "number") lines.push(`- Exit code: \`${item.exitCode}\``);
			if (item.task) lines.push(`- Task: ${item.task}`);
			if (item.error) lines.push(`- Error: ${item.error}`);
			const body = getAssistantText(item.messages) || textFromContent(result?.content);
			if (body.trim()) {
				lines.push("");
				lines.push(body.trim());
			}
			lines.push("");
		}
	} else {
		const body = textFromContent(result?.content);
		lines.push(body.trim() || "No result content was returned.");
	}

	return lines.join("\n");
}

class ResultDialog {
	private markdown: Markdown;
	private scroll = 0;
	private cachedWidth = 0;
	private cachedLines: string[] = [];

	constructor(
		private text: string,
		private theme: any,
		private done: () => void,
	) {
		this.markdown = new Markdown(text, 1, 0, getMarkdownTheme());
	}

	invalidate(): void {
		this.cachedWidth = 0;
		this.cachedLines = [];
		this.markdown.invalidate();
	}

	handleInput(data: string): void {
		if (matchesKey(data, Key.escape) || matchesKey(data, "q") || matchesKey(data, Key.enter)) {
			this.done();
			return;
		}
		if (matchesKey(data, Key.down) || matchesKey(data, "j")) this.scroll += 1;
		if (matchesKey(data, Key.up) || matchesKey(data, "k")) this.scroll = Math.max(0, this.scroll - 1);
		if (matchesKey(data, Key.space)) this.scroll += 10;
	}

	render(width: number): string[] {
		const innerWidth = Math.max(20, width - 4);
		if (this.cachedWidth !== innerWidth) {
			this.cachedWidth = innerWidth;
			this.cachedLines = this.markdown.render(innerWidth);
		}

		const maxBody = 28;
		const body = this.cachedLines.slice(this.scroll, this.scroll + maxBody);
		const total = this.cachedLines.length;
		const footer = `Esc/q/Enter close · ↑/↓/j/k scroll · ${Math.min(this.scroll + body.length, total)}/${total}`;
		const border = "─".repeat(Math.max(0, width - 2));
		const out = [
			this.theme.fg("accent", `┌${border}┐`),
			truncateToWidth(this.theme.bold("│ Subagent result") + " ".repeat(width), width - 1) + this.theme.fg("accent", "│"),
			this.theme.fg("accent", `├${border}┤`),
		];
		for (const line of body) {
			out.push(`│ ${truncateToWidth(line, width - 4).padEnd(Math.max(0, width - 4))} │`);
		}
		out.push(this.theme.fg("accent", `├${border}┤`));
		out.push(`│ ${truncateToWidth(this.theme.fg("dim", footer), width - 4).padEnd(Math.max(0, width - 4))} │`);
		out.push(this.theme.fg("accent", `└${border}┘`));
		return out;
	}
}

export default function subagentResultTui(pi: ExtensionAPI) {
	let currentCtx: ExtensionContext | undefined;
	let opening = false;
	const shownRequestIds = new Set<string>();
	let watchTimer: ReturnType<typeof setInterval> | undefined;

	function isFinalResult(details: SlashDetails | undefined): details is SlashDetails {
		if (!details?.result) return false;
		const results = details.result.details?.results ?? [];
		if (results.length === 0) return true;
		return !results.some((r) => {
			const status = r.progress?.status;
			return status === "running" || status === "pending" || status === "queued";
		});
	}

	async function openResult(details: SlashDetails, ctx = currentCtx): Promise<void> {
		// ctx.hasUI is also true in RPC mode, but custom TUI components are a no-op
		// there. This extension specifically opens a terminal overlay, so require TUI.
		if (!ctx || ctx.mode !== "tui") return;
		if (!isFinalResult(details)) return;
		const requestId = details.requestId;
		if (requestId && shownRequestIds.has(requestId)) return;
		if (opening) return;

		if (requestId) shownRequestIds.add(requestId);
		opening = true;
		try {
			const markdown = buildMarkdown(details);
			await ctx.ui.custom<void>((_tui, theme, _keybindings, done) => new ResultDialog(markdown, theme, done), {
				overlay: true,
				overlayOptions: {
					width: "90%",
					maxHeight: "85%",
					minWidth: 60,
					anchor: "center",
					margin: 1,
				},
			});
		} finally {
			opening = false;
		}
	}

	function scanSessionForFinalResults(ctx = currentCtx): void {
		if (!ctx || ctx.mode !== "tui") return;
		const entries = ctx.sessionManager.getEntries() as Array<{
			type?: string;
			customType?: string;
			details?: unknown;
			message?: { customType?: string; details?: unknown };
		}>;

		for (const entry of entries) {
			const customType = entry.customType ?? entry.message?.customType;
			if (customType !== SLASH_RESULT_TYPE) continue;
			const details = (entry.details ?? entry.message?.details) as SlashDetails | undefined;
			if (!isFinalResult(details)) continue;
			void openResult(details, ctx);
		}
	}

	function ensureWatcher(ctx = currentCtx): void {
		if (!ctx || ctx.mode !== "tui" || watchTimer) return;
		watchTimer = setInterval(() => scanSessionForFinalResults(ctx), 500);
	}

	function stopWatcher(): void {
		if (!watchTimer) return;
		clearInterval(watchTimer);
		watchTimer = undefined;
	}

	pi.on("session_start", (_event, ctx) => {
		currentCtx = ctx;
		if (ctx.mode === "tui") ensureWatcher(ctx);
	});

	pi.on("session_shutdown", () => {
		stopWatcher();
		currentCtx = undefined;
	});

	// Start/keep the watcher around /run invocations. This is the reliable path:
	// pi-subagents persists both the visible "running" message and hidden final
	// result as custom_message entries in the session, even when no message_end
	// event is emitted for the hidden final result.
	pi.on("input", (event, ctx) => {
		if (ctx.mode !== "tui") return;
		if (event.text.trim().startsWith("/run")) ensureWatcher(ctx);
	});

	// pi-subagents emits /run results with pi.sendMessage(). In current pi,
	// message_end is not a reliable hook for extension custom_message entries,
	// especially when the final /run result uses display:false in TUI mode.
	// Patch sendMessage so we can observe the hidden final result immediately.
	const originalSendMessage = pi.sendMessage.bind(pi);
	(pi as unknown as { sendMessage: typeof pi.sendMessage }).sendMessage = (message: Parameters<typeof pi.sendMessage>[0], options?: Parameters<typeof pi.sendMessage>[1]) => {
		const result = originalSendMessage(message, options);
		const maybeMessage = message as unknown as { customType?: string; details?: unknown };
		if (maybeMessage.customType === SLASH_RESULT_TYPE) {
			const details = maybeMessage.details as SlashDetails | undefined;
			if (details?.result) setTimeout(() => void openResult(details), 0);
		}
		return result;
	};

	// Fallback for runtimes that do emit message_end for custom messages.
	pi.on("message_end", async (event, ctx) => {
		const message = event.message as unknown as { customType?: string; details?: unknown };
		if (message.customType !== SLASH_RESULT_TYPE) return;
		await openResult(message.details as SlashDetails | undefined, ctx);
	});

	pi.registerCommand("subagent-result-preview", {
		description: "Show a sample subagent result overlay to test the TUI",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) return;
			await ctx.ui.custom<void>((_tui, theme, _keybindings, done) => new ResultDialog(`# Subagent result\n\nThis is a preview. Run \`/run <agent> <task>\` to show real results here.`, theme, done), {
				overlay: true,
				overlayOptions: { width: "80%", minWidth: 50, anchor: "center", margin: 1 },
			});
		},
	});
}

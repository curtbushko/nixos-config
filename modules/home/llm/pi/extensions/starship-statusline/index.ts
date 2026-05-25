/**
 * Starship-style footer for Pi with message styling
 */
import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { CustomEditor, UserMessageComponent } from "@earendil-works/pi-coding-agent";
import type { TUI, EditorTheme, EditorOptions } from "@earendil-works/pi-tui";
import type { KeybindingsManager } from "@earendil-works/pi-coding-agent";
import { visibleWidth, CURSOR_MARKER, truncateToWidth, Markdown } from "@earendil-works/pi-tui";
import type { MarkdownTheme } from "@earendil-works/pi-tui";
import { exec } from "node:child_process";
import { promisify } from "node:util";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const execAsync = promisify(exec);

// VCS Cache
interface VcsInfo {
  branch: string;
  dirty: boolean;
}

let vcsCache: { info: VcsInfo | null; time: number; cwd: string } = {
  info: null,
  time: 0,
  cwd: "",
};

const CACHE_TTL = 2000;

async function getVcsInfo(cwd: string): Promise<VcsInfo | null> {
  try {
    const { stdout: branch } = await execAsync("git branch --show-current", { cwd, timeout: 300 });
    const { stdout: status } = await execAsync("git status --porcelain", { cwd, timeout: 300 });
    return {
      branch: branch.trim() || "HEAD",
      dirty: status.trim().length > 0,
    };
  } catch {
    return null;
  }
}

async function refreshVcs(cwd: string): Promise<void> {
  const now = Date.now();
  if (vcsCache.cwd === cwd && now - vcsCache.time < CACHE_TTL) return;

  vcsCache.cwd = cwd;
  vcsCache.time = now;
  vcsCache.info = await getVcsInfo(cwd);
}

// Load colors
const COLORS_PATH = join(process.env.HOME || "", ".pi/agent/extensions/starship-statusline/colors.json");
let COLORS = {
  a_bg: "#1d2021",
  a_fg: "#d4be98",
  b_bg: "#282828",
  b_fg: "#d4be98",
  c_bg: "#3c3836",
  c_fg: "#a9b665",
  error: "#ea6962",
};

try {
  const data = readFileSync(COLORS_PATH, "utf-8");
  // Handle potential duplication by taking first JSON object
  const firstBrace = data.indexOf("{");
  const lastBrace = data.indexOf("}", firstBrace) + 1;
  if (firstBrace >= 0 && lastBrace > firstBrace) {
    COLORS = { ...COLORS, ...JSON.parse(data.slice(firstBrace, lastBrace)) };
  }
} catch {}

// ANSI helpers
function rgb(hex: string): string {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `${r};${g};${b}`;
}

const fg = (hex: string) => `\x1b[38;2;${rgb(hex)}m`;
const bg = (hex: string) => `\x1b[48;2;${rgb(hex)}m`;
const RESET = "\x1b[0m";

// ============================================================================
// User Message Styling (zentui-inspired framed messages)
// ============================================================================

type RenderFn = (width: number) => string[];
type PatchablePrototype = {
  render: RenderFn;
  children?: unknown[];
  __starshipOriginalRender?: RenderFn;
  __starshipPatched?: boolean;
};

// Theme reference for message styling
let messageTheme: Theme | undefined;

function findMarkdownText(value: unknown): string | undefined {
  if (typeof value === "object" && value !== null && "text" in value) {
    const v = value as { text?: unknown };
    if (typeof v.text === "string") return v.text;
  }
  if (typeof value !== "object" || value === null) return undefined;
  const children = Array.isArray((value as { children?: unknown[] }).children)
    ? (value as { children: unknown[] }).children
    : [];
  for (const child of children) {
    const text = findMarkdownText(child);
    if (text !== undefined) return text;
  }
  return undefined;
}

function makeMarkdownTheme(theme: Theme | undefined): MarkdownTheme {
  const themeFg = (color: string, text: string) => {
    if (!theme) return text;
    try { return theme.fg(color as any, text); } catch { return text; }
  };
  return {
    heading: (text) => themeFg("mdHeading", text),
    link: (text) => themeFg("mdLink", text),
    linkUrl: (text) => themeFg("mdLinkUrl", text),
    code: (text) => themeFg("mdCode", text),
    codeBlock: (text) => themeFg("mdCodeBlock", text),
    codeBlockBorder: (text) => themeFg("mdCodeBlockBorder", text),
    quote: (text) => themeFg("mdQuote", text),
    quoteBorder: (text) => themeFg("mdQuoteBorder", text),
    hr: (text) => themeFg("mdHr", text),
    listBullet: (text) => themeFg("mdListBullet", text),
    bold: (text) => theme?.bold(text) ?? text,
    italic: (text) => theme?.italic(text) ?? text,
    underline: (text) => theme?.underline(text) ?? text,
    strikethrough: (text) => theme?.strikethrough(text) ?? text,
  };
}

function fillLine(content: string, width: number): string {
  const truncated = truncateToWidth(content, Math.max(0, width), "");
  const pad = " ".repeat(Math.max(0, width - visibleWidth(truncated)));
  return `${truncated}${pad}`;
}

function renderFramedMessage(instance: PatchablePrototype, width: number): string[] | undefined {
  const text = findMarkdownText(instance);
  if (text === undefined) return undefined;
  if (width <= 0) return [""];

  const theme = messageTheme;
  const accentColor = COLORS.c_fg; // Use statusline accent color for rail
  const borderColor = COLORS.b_bg; // Use muted color for border

  // Rail character with color
  const rail = fg(accentColor) + "│" + RESET + " ";
  const railWidth = 2; // "│ "
  const contentWidth = Math.max(1, width - railWidth);

  // Render markdown content
  const renderer = new Markdown(text, 0, 0, makeMarkdownTheme(theme), {
    color: (content) => theme ? theme.fg("userMessageText" as any, content) : content,
  });
  const body = renderer.render(contentWidth);
  const contentLines = body.length > 0 ? body : [""];

  // Border line
  const border = fg(borderColor) + "─".repeat(width) + RESET;

  // Build framed output
  const renderLine = (line: string) => {
    const padded = fillLine(line, contentWidth);
    return fg(accentColor) + "│" + RESET + " " + padded;
  };

  return [
    border,
    ...contentLines.map(renderLine),
    border,
  ];
}

function installUserMessageStyle(): void {
  const prototype = UserMessageComponent.prototype as unknown as PatchablePrototype;
  if (prototype.__starshipPatched) return;

  prototype.__starshipOriginalRender = prototype.render;
  prototype.render = function (this: PatchablePrototype, width: number): string[] {
    const original = prototype.__starshipOriginalRender ?? prototype.render;
    const lines = renderFramedMessage(this, width);
    if (!lines) return original.call(this, width);
    return lines;
  };
  prototype.__starshipPatched = true;
}

// Repo icons
const REPO_ICONS: Record<string, string> = {
  "kb": "󰧑 ",
  "nixos-config": "󱄅 ",
  "ghostty": "󰊠 ",
  "neovim-flake": " ",
  "terraform": "󱁢 ",
  "Downloads": " ",
};

/**
 * Starship Editor with ❯ prompt and vim-style ex command support
 */
export class StarshipEditor extends CustomEditor {
  private readonly ctx?: ExtensionContext;
  private readonly fallbackTheme: EditorTheme;
  private commandMode: boolean = false;
  private commandBuffer: string = "";

  constructor(
    tui: TUI,
    editorTheme: EditorTheme,
    kb: KeybindingsManager,
    opts?: EditorOptions,
    ctx?: ExtensionContext,
  ) {
    super(tui, editorTheme, kb, opts, ctx);
    this.ctx = ctx;
    this.fallbackTheme = editorTheme;
  }

  override handleInput(data: string): void {
    // Handle command mode
    if (this.commandMode) {
      this.handleCommandInput(data);
      return;
    }

    // Enter command mode on ":"
    if (data === ":") {
      this.commandMode = true;
      this.commandBuffer = "";
      this.invalidate();
      return;
    }

    // Normal input handling
    super.handleInput(data);
  }

  private handleCommandInput(data: string): void {
    // Exit command mode on Escape
    if (data === "\x1b") {
      this.commandMode = false;
      this.commandBuffer = "";
      this.invalidate();
      return;
    }

    // Execute command on Enter
    if (data === "\r" || data === "\n") {
      this.executeCommand(this.commandBuffer);
      this.commandMode = false;
      this.commandBuffer = "";
      this.invalidate();
      return;
    }

    // Handle backspace
    if (data === "\x7f" || data === "\b") {
      if (this.commandBuffer.length > 0) {
        this.commandBuffer = this.commandBuffer.slice(0, -1);
      } else {
        // Exit command mode if buffer is empty
        this.commandMode = false;
      }
      this.invalidate();
      return;
    }

    // Append to command buffer
    if (data.length === 1 && data >= " " && data <= "~") {
      this.commandBuffer += data;
      this.invalidate();
    }
  }

  private executeCommand(cmd: string): void {
    const trimmed = cmd.trim();

    switch (trimmed) {
      case "q":
      case "quit":
        // Exit pi - trigger ctrl+d behavior when editor is empty
        if (this.getText().trim() === "") {
          process.exit(0);
        }
        break;

      case "q!":
      case "quit!":
        // Force exit
        process.exit(0);
        break;

      case "w":
      case "write":
        // Pi auto-saves, so just show a message
        // Could emit an event here if needed
        break;

      case "wq":
      case "x":
        // Save and exit
        process.exit(0);
        break;

      default:
        // Unknown command - could show error message
        break;
    }
  }

  render(width: number): string[] {
    const theme = this.ctx?.ui.theme ?? this.fallbackTheme;

    // Command mode prompt
    if (this.commandMode) {
      const cmdPrompt = theme.fg("warning", ":") + this.commandBuffer + (this.focused ? CURSOR_MARKER : "");
      return [cmdPrompt];
    }

    // Normal prompt
    const prompt = theme.bold(theme.fg("success", "❯")) + " ";
    const promptW = visibleWidth(prompt);
    const innerW = Math.max(10, width - promptW);

    const origBorder = this.borderColor;
    this.borderColor = () => "";
    const raw = super.render(innerW);
    this.borderColor = origBorder;

    const lines = raw.filter((l) => l !== "");
    if (lines.length === 0) return [prompt + (this.focused ? CURSOR_MARKER : "")];

    const indent = " ".repeat(promptW);
    return [prompt + lines[0], ...lines.slice(1).map((l) => indent + l)];
  }
}

// Build statusline
function buildStatusline(ctx: ExtensionContext): string {
  const parts: string[] = [];
  const v = vcsCache.info;

  // Get repo name
  const cwd = ctx.cwd;
  const home = process.env.HOME || "";
  const repoName = cwd.startsWith(home)
    ? cwd.slice(home.length + 1).split("/").pop() || "~"
    : cwd.split("/").pop() || cwd;
  const repoIcon = REPO_ICONS[repoName] || "󰊢 ";

  let spacer = bg(COLORS.c_bg) + fg(COLORS.c_bg) + " ";
  parts.push(spacer);
  // Segment A: Gradient + Model
  let segA = bg(COLORS.a_bg) + fg(COLORS.a_fg) + "▓▒░";
  if (ctx.model?.id) {
    const model = ctx.model.id.replace("gpt-", "gpt-");
    segA += " 󰭹 " + model + " ";
  }
  parts.push(segA);

  // Separator A → B
  parts.push(bg(COLORS.b_bg) + fg(COLORS.a_bg) + " ");

  // Segment B: Repo
  parts.push(bg(COLORS.b_bg) + fg(COLORS.b_fg) + " " + repoIcon + " " + repoName + " ");

  // Separator B → C 
  parts.push(bg(COLORS.c_bg) + fg(COLORS.b_bg) + " ");

  // Segment C: Git (if exists)
  if (v) {
    parts.push(bg(COLORS.c_bg) + fg(COLORS.b_bg) + "");
    let segC = bg(COLORS.c_bg) + fg(COLORS.c_fg) + " " + v.branch;
    if (v.dirty) segC += " ✘!+?";
    segC += " ";
    parts.push(segC);
    parts.push(RESET + fg(COLORS.c_bg) + "" + RESET);
  } else {
    parts.push(RESET + fg(COLORS.b_bg) + "" + RESET);
  }

  return parts.join("");
}

// Extension setup
let updateTimer: NodeJS.Timeout | null = null;

function scheduleUpdate(ctx: ExtensionContext): void {
  if (updateTimer) clearTimeout(updateTimer);
  updateTimer = setTimeout(() => {
    refreshVcs(ctx.cwd).then(() => {
      ctx.ui.setFooter((tui) => ({
        dispose: () => {},
        invalidate: () => {},
        render: () => [buildStatusline(ctx)],
      }));
    });
  }, 300);
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_e, ctx) => {
    if (!ctx.hasUI) return;

    // Install user message styling (framed messages)
    messageTheme = ctx.ui.theme;
    installUserMessageStyle();

    // Don't set editor component - let pi-vim-ex handle that
    // Only set up the statusline footer

    // Initial statusline
    await refreshVcs(ctx.cwd);
    ctx.ui.setFooter((tui) => ({
      dispose: () => {},
      invalidate: () => {},
      render: () => [buildStatusline(ctx)],
    }));
  });

  pi.on("model_select", (_e, ctx) => {
    messageTheme = ctx.ui.theme;
    scheduleUpdate(ctx);
  });
  pi.on("user_bash", (_e, ctx) => scheduleUpdate(ctx));
  pi.on("session_switch", (_e, ctx) => {
    messageTheme = ctx.ui.theme;
    scheduleUpdate(ctx);
  });
}

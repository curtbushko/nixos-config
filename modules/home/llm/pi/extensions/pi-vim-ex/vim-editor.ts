/**
 * VimEditor - Modal vim editor extending CustomEditor.
 * Routes input to mode-specific handlers and renders mode indicator.
 */

import { CustomEditor } from "@earendil-works/pi-coding-agent";
import {
  matchesKey,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import type { TUI, EditorOptions, EditorTheme, AutocompleteProvider } from "@earendil-works/pi-tui";
import { createInitialState, modeDisplayName, type VimState } from "./state.js";
import { handleNormalMode, type NormalModeContext } from "./modes/normal.js";
import { handleInsertMode, type InsertModeContext } from "./modes/insert.js";
import { handleReplaceMode, type ReplaceModeContext } from "./modes/replace.js";
import { handleVisualMode, getVisualRange, type VisualModeContext } from "./modes/visual.js";
import { ESCAPE_SEQS } from "./keys.js";
import {
  handleSearchInput,
  getSearchPrompt,
  getSearchState,
  executeSearchMotion,
} from "./search.js";
import { executeExCommand } from "./ex-commands.js";

export class VimEditor extends CustomEditor {
  public vimState: VimState;
  private redoStack: Array<{ lines: string[]; cursorLine: number; cursorCol: number }> = [];
  private wrapAutocomplete: ((provider: AutocompleteProvider) => AutocompleteProvider) | undefined;
  private commandDraft: string | null = null;
  private commandPrefix: ":" | "!" = ":";
  private tui: TUI;

  constructor(
    tui: TUI,
    theme: EditorTheme,
    keybindings: any,
    options?: EditorOptions,
    wrapAutocomplete?: (provider: AutocompleteProvider) => AutocompleteProvider,
  ) {
    super(tui, theme, keybindings, options);
    this.tui = tui;
    this.vimState = createInitialState();
    this.wrapAutocomplete = wrapAutocomplete;
  }


  /**
   * Wrap the autocomplete provider with fuzzy file matching for @ queries.
   * This integrates pi-fzfp's weighted dual-key scoring into the vim editor.
   */
  override setAutocompleteProvider(provider: AutocompleteProvider): void {
    super.setAutocompleteProvider(this.wrapAutocomplete ? this.wrapAutocomplete(provider) : provider);
  }

  /**
   * Undo: snapshot current state to redo stack, then perform base editor undo.
   * Works at the same level as the base editor's internal state.
   */
  vimUndo(): void {
    const editor = this as any;
    if (!editor.undoStack || editor.undoStack.length === 0) return;

    // Save current internal state to redo stack before undoing
    const state = editor.state;
    this.redoStack.push(structuredClone(state));

    // Perform base editor undo
    editor.undo();
  }

  /**
   * Redo: restore state from redo stack, push current state to undo stack.
   * Mirrors the base editor's undo mechanism in reverse.
   */
  vimRedo(): void {
    if (this.redoStack.length === 0) return;
    const editor = this as any;
    const snapshot = this.redoStack.pop()!;

    // Push current state to undo stack
    editor.undoStack.push(structuredClone(editor.state));

    // Restore the redo snapshot directly into internal state
    Object.assign(editor.state, snapshot);
    editor.lastAction = null;
    editor.preferredVisualCol = null;
    if (editor.onChange) {
      editor.onChange(this.getText());
    }
  }

  handleInput(data: string): void {
    if (this.isReturn(data) && this.getText().startsWith(":")) {
      if (this.handleLeadingColonCommand()) {
        this.tui.requestRender();
        return;
      }
    }
    if (this.isReturn(data) && this.getText().startsWith("!")) {
      if (this.handleLeadingBangCommand()) {
        this.tui.requestRender();
        return;
      }
    }

    const { vimState } = this;
    const modeBefore = vimState.mode;
    const textBefore = this.getText();
    const redoStackBefore = this.redoStack.length;

    switch (vimState.mode) {
      case "insert":
        this.handleInsert(data);
        break;

      case "replace":
        this.handleReplace(data);
        break;

      case "normal":
        this.handleNormal(data);
        break;

      case "visual":
      case "visual-line":
        this.handleVisual(data);
        break;

      case "command-line":
      case "shell":
        this.handleCommandLine(data);
        break;

      default:
        // For unimplemented modes, pass through to super
        super.handleInput(data);
        break;
    }

    // Clear redo stack when text changes from a non-undo/redo action.
    // If the redo stack changed size, it was an undo/redo operation — don't clear.
    if (this.redoStack.length === redoStackBefore && this.getText() !== textBefore) {
      this.redoStack.length = 0;
    }
    if (vimState.mode !== modeBefore || this.getText() !== textBefore) {
      this.tui.requestRender();
    }
  }

  private isReturn(data: string): boolean {
    return matchesKey(data, "return") || data === "\r" || data === "\n";
  }

  /**
   * Treat a submitted prompt beginning with ':' as command input.
   *
   * Vim ex commands such as :q are interpreted locally. Unknown ex commands are
   * forwarded to Pi as slash commands, so typing `:model`, `:help`, etc. in the
   * normal text input behaves like `/model`, `/help`, and so on.
   */
  private handleLeadingColonCommand(): boolean {
    const command = this.getText().slice(1).trim();
    if (!command) {
      if (this.commandDraft === null) return false;
      this.finishExCommand();
      return true;
    }

    const exResult = executeExCommand(command);
    const draft = this.commandDraft;
    this.commandDraft = null;
    if (draft !== null) this.vimState.mode = "normal";
    if (exResult === "exit") {
      this.submitSlashCommand("quit");
    } else if (exResult === "continue") {
      this.setText(draft ?? "");
    } else {
      this.submitSlashCommand(command);
      if (draft !== null) this.setText(draft);
    }
    return true;
  }

  private beginExCommand(prefix: ":" | "!" = ":"): void {
    this.commandDraft = this.getText();
    this.commandPrefix = prefix;
    this.setText(prefix);
    this.vimState.mode = prefix === "!" ? "shell" : "command-line";
    this.vimState.visualAnchor = null;
  }

  private finishExCommand(): void {
    this.setText(this.commandDraft ?? "");
    this.commandDraft = null;
    this.commandPrefix = ":";
    this.vimState.mode = "normal";
  }

  private handleLeadingBangCommand(): boolean {
    const command = this.getText().slice(1).trim();
    const draft = this.commandDraft;
    this.commandDraft = null;
    this.commandPrefix = ":";
    if (draft !== null) this.vimState.mode = "normal";
    if (!command) {
      this.setText(draft ?? "");
      return true;
    }
    this.submitSlashCommand(`shell ${command}`);
    if (draft !== null) this.setText(draft);
    return true;
  }

  private submitSlashCommand(command: string): void {
    const normalized = command.startsWith("/") ? command : `/${command}`;
    this.setText(normalized);
    super.handleInput("\r");
  }

  private handleInsert(data: string): void {
    const ctx: InsertModeContext = {
      state: this.vimState,
      getCursor: () => this.getCursor(),
      superHandleInput: (d) => super.handleInput(d),
    };
    handleInsertMode(data, ctx);
  }

  private handleReplace(data: string): void {
    const ctx: ReplaceModeContext = {
      state: this.vimState,
      getCursor: () => this.getCursor(),
      getText: () => this.getText(),
      setText: (text) => this.setText(text),
      moveCursorTo: (line, col) => this.moveCursorTo(line, col),
      superHandleInput: (d) => super.handleInput(d),
    };
    handleReplaceMode(data, ctx);
  }

  private handleNormal(data: string): void {
    // Escape in normal mode → consume it (don't pass to super to avoid opening session tree)
    if (matchesKey(data, "escape")) {
      // Just stay in normal mode, do nothing
      return;
    }

    if (data === ":") {
      this.beginExCommand(":");
      return;
    }

    if (data === "!") {
      this.beginExCommand("!");
      return;
    }

    const ctx: NormalModeContext = {
      state: this.vimState,
      superHandleInput: (d) => super.handleInput(d),
      getText: () => this.getText(),
      getCursor: () => this.getCursor(),
      setText: (text) => this.setText(text),
      moveCursorTo: (line, col) => this.moveCursorTo(line, col),
      undo: () => this.vimUndo(),
      redo: () => this.vimRedo(),
    };
    handleNormalMode(data, ctx);
  }

  private handleCommandLine(data: string): void {
    const searchState = getSearchState();

    if (this.commandDraft !== null) {
      const prefix = this.commandPrefix;
      if (matchesKey(data, "escape")) {
        this.finishExCommand();
      } else if (this.getText() === prefix && matchesKey(data, "backspace")) {
        this.finishExCommand();
      } else if (this.isReturn(data)) {
        if (prefix === "!" && this.getText().startsWith("!")) this.handleLeadingBangCommand();
        else if (this.getText().startsWith(":")) this.handleLeadingColonCommand();
        else this.finishExCommand();
      } else {
        super.handleInput(data);
      }
    } else if (searchState.active) {
      // Handle search input
      const returnMode = searchState.returnMode;
      const result = handleSearchInput(data);

      if (result === "confirm") {
        // Execute the search and move cursor to the match
        const lines = this.getText().split("\n");
        const cursor = this.getCursor();
        const motionResult = executeSearchMotion(lines, cursor);
        this.moveCursorTo(motionResult.position.line, motionResult.position.col);
        this.vimState.mode = returnMode;
      } else if (result === "cancel") {
        this.vimState.mode = "normal";
        this.vimState.visualAnchor = null;
      }
      // "continue" → stay in command-line mode
    }
  }

  private handleVisual(data: string): void {
    if (data === ":") {
      this.beginExCommand(":");
      return;
    }

    if (data === "!") {
      this.beginExCommand("!");
      return;
    }

    const ctx: VisualModeContext = {
      state: this.vimState,
      superHandleInput: (d) => super.handleInput(d),
      getText: () => this.getText(),
      getCursor: () => this.getCursor(),
      setText: (text) => this.setText(text),
      moveCursorTo: (line, col) => this.moveCursorTo(line, col),
    };
    handleVisualMode(data, ctx);
  }

  /**
   * Move cursor to an absolute position by using escape sequences.
   * Re-reads getCursor() for accurate positioning (important after setText which moves to end).
   */
  moveCursorTo(targetLine: number, targetCol: number): void {
    const current = this.getCursor();

    // Move vertically
    if (targetLine < current.line) {
      for (let i = current.line; i > targetLine; i--) {
        super.handleInput(ESCAPE_SEQS.up);
      }
    } else if (targetLine > current.line) {
      for (let i = current.line; i < targetLine; i++) {
        super.handleInput(ESCAPE_SEQS.down);
      }
    }

    // Move to line start, then right to target column
    super.handleInput(ESCAPE_SEQS.home);
    for (let i = 0; i < targetCol; i++) {
      super.handleInput(ESCAPE_SEQS.right);
    }
  }

  render(width: number): string[] {
    // Mode colors (RGB values from flair theme)
    // Color triples are substituted from flair's active theme at build time
    // by modules/home/llm/pi/default.nix. See placeholders below.
    const GREEN = "\x1b[38;2;@base0B_rgb@m";  // INSERT - base0B
    const BLUE = "\x1b[38;2;@base0D_rgb@m";   // NORMAL - base0D
    const ORANGE = "\x1b[38;2;@base09_rgb@m"; // VISUAL / REPLACE / COMMAND-LINE - base09
    const RED = "\x1b[38;2;@base08_rgb@m";    // SHELL - base08
    const RESET = "\x1b[0m";

    // Use the same accent for the prompt label, rail, and command prefix.
    // Leading `!` / `:` in the buffer overrides the mode color so INSERT-mode
    // typing of `!ls` or `:help` reads as SHELL/COMMAND.
    let railColor = BLUE;
    if (this.getText().startsWith("!") || this.vimState.mode === "shell") {
      railColor = RED;
    } else if (this.getText().startsWith(":") || this.vimState.mode === "command-line") {
      railColor = ORANGE;
    } else if (this.vimState.mode === "insert") {
      railColor = GREEN;
    } else if (this.vimState.mode === "visual" || this.vimState.mode === "visual-line") {
      railColor = ORANGE;
    } else if (this.vimState.mode === "replace") {
      railColor = ORANGE;
    }

    // Rail: "│ " (2 chars)
    const railWidth = 2;
    const contentWidth = Math.max(1, width - railWidth);

    const modeLabel = this.getText().startsWith("!")
      ? "SHELL"
      : this.getText().startsWith(":")
        ? "COMMAND"
        : modeDisplayName(this.vimState.mode);
    const borderLabel = ` ${modeLabel} `;

    const renderBorder = (label?: string) => {
      if (!label || width <= visibleWidth(label) + 2) {
        return railColor + "─".repeat(width) + RESET;
      }

      const labelWidth = visibleWidth(label);
      const leftLen = Math.floor((width - labelWidth) / 2);
      const rightLen = width - labelWidth - leftLen;
      return railColor + "─".repeat(leftLen) + label + "─".repeat(rightLen) + RESET;
    };

    const topBorder = renderBorder(borderLabel);
    const bottomBorder = renderBorder();

    // Helper to render a pre-wrapped line with the colored rail.
    // Pi TUI requires each rendered line to fit within `width`; wrapping here
    // preserves the custom rail while allowing long prompts to flow naturally.
    const renderLine = (content: string) => {
      const safeContent = truncateToWidth(content, contentWidth, "");
      const padLen = Math.max(0, contentWidth - visibleWidth(safeContent));
      return railColor + "│" + RESET + " " + safeContent + " ".repeat(padLen);
    };

    const renderWrappedLine = (content: string) => {
      const wrapped = wrapTextWithAnsi(content, contentWidth);
      const lines = wrapped.length > 0 ? wrapped : [""];
      return lines.map(renderLine);
    };

    // Handle command-line mode prompts (search/ex commands)
    let promptPrefix = "";
    if (this.vimState.mode === "command-line") {
      const searchState = getSearchState();
      if (searchState.active) {
        promptPrefix = railColor + getSearchPrompt() + RESET + " ";
      }
    }

    // Get raw text content and split into lines
    const text = this.getText();
    const textLines = text.split("\n");
    const cursor = this.getCursor();

    // Apply visual selection highlighting
    const isVisual = this.vimState.mode === "visual" || this.vimState.mode === "visual-line";
    const isSearchFromVisual =
      this.vimState.mode === "command-line" &&
      (getSearchState().returnMode === "visual" || getSearchState().returnMode === "visual-line");

    // Build output: border, content, border (no padding)
    const output: string[] = [];

    // Top border
    output.push(topBorder);

    // Get visual selection range if in visual mode
    let visualRange: { start: { line: number; col: number }; end: { line: number; col: number }; linewise: boolean } | null = null;
    if ((isVisual || isSearchFromVisual) && this.vimState.visualAnchor) {
      visualRange = getVisualRange(this.vimState, cursor, textLines);
    }

    // Content lines with cursor and visual highlighting
    for (let i = 0; i < textLines.length; i++) {
      let line = textLines[i] || "";

      // Apply visual selection highlighting
      if (visualRange && i >= visualRange.start.line && i <= visualRange.end.line) {
        const startCol = visualRange.linewise ? 0 : (i === visualRange.start.line ? visualRange.start.col : 0);
        const endCol = visualRange.linewise ? line.length : (i === visualRange.end.line ? visualRange.end.col + 1 : line.length);
        const before = line.slice(0, startCol);
        const selected = line.slice(startCol, endCol);
        const after = line.slice(endCol);
        line = before + "\x1b[7m" + selected + "\x1b[27m" + after;
      }

      // Insert cursor marker at cursor position (if not in visual selection)
      if (i === cursor.line && this.focused && !visualRange) {
        const before = line.slice(0, cursor.col);
        const cursorChar = line[cursor.col] || " ";
        const after = line.slice(cursor.col + 1);
        line = before + "\x1b[7m" + cursorChar + "\x1b[27m" + after;
      }

      // Add command-line prompt prefix to first line
      if (i === 0 && promptPrefix) {
        line = promptPrefix + line;
      }

      output.push(...renderWrappedLine(line));
    }

    // Bottom border
    output.push(bottomBorder);

    return output;
  }

  /**
   * Apply reverse-video highlighting to the visual selection range in rendered output.
   *
   * The rendered output from super.render() is structured as:
   *   [top border, ...content lines (with padding), bottom border, ...autocomplete]
   *
   * Content lines have format: `${leftPadding}${displayText}${rightPadding}`
   * where padding is `paddingX` spaces on each side (default 0).
   * The editor also inserts CURSOR_MARKER (APC sequence) and cursor highlighting.
   *
   * We use pi-tui's extractAnsiCode to properly skip ALL escape sequences
   * (CSI, OSC, APC) when counting visible positions.
   */
  private applyVisualHighlight(renderedLines: string[], width: number): void {
    const text = this.getText();
    const textLines = text.split("\n");
    const cursor = this.getCursor();
    const range = getVisualRange(this.vimState, cursor, textLines);

    // The editor uses paddingX (default 0) for left/right content padding.
    // With paddingX=0: contentWidth = width, layoutWidth = width - 1
    // Content lines start at renderedLines[1] through renderedLines[length-2].
    // The padding property is accessed via getPadding().
    const paddingX = this.getPaddingX();
    const contentWidth = Math.max(1, width - paddingX * 2);
    const layoutWidth = Math.max(1, contentWidth - (paddingX ? 0 : 1));

    // Map text line index → first rendered line index (1-based, after top border)
    const textLineToRenderedStart: number[] = [];
    let renderedIdx = 1; // skip top border
    for (let i = 0; i < textLines.length; i++) {
      textLineToRenderedStart.push(renderedIdx);
      const lineLen = Math.max(1, visibleWidth(textLines[i] || ""));
      const wrappedCount = Math.ceil(lineLen / layoutWidth);
      renderedIdx += wrappedCount;
    }

    // Highlight the selected ranges
    for (let textLine = range.start.line; textLine <= range.end.line; textLine++) {
      const lineText = textLines[textLine] || "";
      const renderedStart = textLineToRenderedStart[textLine];
      if (renderedStart === undefined) continue;

      let selStartCol: number;
      let selEndCol: number;

      if (range.linewise) {
        selStartCol = 0;
        selEndCol = lineText.length;
      } else {
        selStartCol = textLine === range.start.line ? range.start.col : 0;
        selEndCol =
          textLine === range.end.line ? range.end.col + 1 : lineText.length;
      }

      // Apply highlighting across wrapped lines
      const lineLen = Math.max(1, lineText.length);
      const wrappedCount = Math.ceil(lineLen / layoutWidth);

      for (let wrap = 0; wrap < wrappedCount; wrap++) {
        const rIdx = renderedStart + wrap;
        if (rIdx >= renderedLines.length - 1) break; // don't touch bottom border

        const wrapStartCol = wrap * layoutWidth;
        const wrapEndCol = wrapStartCol + layoutWidth;

        // Intersection of selection with this wrapped segment
        const hlStart = Math.max(selStartCol, wrapStartCol) - wrapStartCol;
        const hlEnd = Math.min(selEndCol, wrapEndCol) - wrapStartCol;

        if (hlStart < hlEnd) {
          // Offset by paddingX for left padding
          renderedLines[rIdx] = highlightRenderedLine(
            renderedLines[rIdx]!,
            hlStart + paddingX,
            hlEnd + paddingX,
          );
        }
      }
    }
  }
}

/**
 * Detect an escape sequence at position `pos` in `str`.
 * Returns the length of the escape sequence, or 0 if none found.
 *
 * Handles:
 * - CSI sequences: \x1b[ ... m/G/K/H/J
 * - OSC sequences: \x1b] ... BEL or \x1b] ... ST(\x1b\\)
 * - APC sequences: \x1b_ ... BEL or \x1b_ ... ST(\x1b\\)
 */
function escapeSeqLength(str: string, pos: number): number {
  if (pos >= str.length || str[pos] !== "\x1b") return 0;
  const next = str[pos + 1];

  // CSI: \x1b[ ... terminator
  if (next === "[") {
    let j = pos + 2;
    while (j < str.length && !/[mGKHJ]/.test(str[j]!)) j++;
    if (j < str.length) return j + 1 - pos;
    return 0;
  }

  // OSC: \x1b] ... BEL or ST
  if (next === "]") {
    let j = pos + 2;
    while (j < str.length) {
      if (str[j] === "\x07") return j + 1 - pos;
      if (str[j] === "\x1b" && str[j + 1] === "\\") return j + 2 - pos;
      j++;
    }
    return 0;
  }

  // APC: \x1b_ ... BEL or ST
  if (next === "_") {
    let j = pos + 2;
    while (j < str.length) {
      if (str[j] === "\x07") return j + 1 - pos;
      if (str[j] === "\x1b" && str[j + 1] === "\\") return j + 2 - pos;
      j++;
    }
    return 0;
  }

  return 0;
}

/**
 * Insert reverse-video ANSI codes into a rendered line at specific visible column positions.
 * Properly handles CSI, OSC, and APC escape sequences (including CURSOR_MARKER).
 *
 * When the cursor falls inside the highlighted range, the editor's cursor rendering
 * inserts `\x1b[0m` (full reset) after the cursor character, which would kill the
 * reverse video for the rest of the selection. We detect this and re-inject `\x1b[7m`
 * after any SGR reset that falls within the highlighted range.
 *
 * `startVisCol` and `endVisCol` are 0-indexed visible column positions to highlight.
 */
function highlightRenderedLine(
  line: string,
  startVisCol: number,
  endVisCol: number,
): string {
  let result = "";
  let visCol = 0;
  let i = 0;
  let started = false;
  let ended = false;

  while (i < line.length) {
    // Check for any escape sequence (CSI, OSC, APC)
    const seqLen = escapeSeqLength(line, i);
    if (seqLen > 0) {
      // Insert highlight markers before this escape sequence if needed
      if (!started && visCol >= startVisCol) {
        result += "\x1b[7m";
        started = true;
      }
      if (started && !ended && visCol >= endVisCol) {
        result += "\x1b[27m";
        ended = true;
      }

      const seq = line.substring(i, i + seqLen);
      result += seq;

      // If we're inside the highlight range and this is a SGR reset (\x1b[0m),
      // re-inject reverse video to keep the selection highlighted.
      // The editor's cursor rendering uses \x1b[0m after the cursor character,
      // which would otherwise kill our reverse video.
      if (started && !ended && isResetSequence(seq)) {
        result += "\x1b[7m";
      }

      i += seqLen;
      continue;
    }

    // Insert highlight markers at the right visible positions
    if (!started && visCol === startVisCol) {
      result += "\x1b[7m";
      started = true;
    }
    if (started && !ended && visCol === endVisCol) {
      result += "\x1b[27m";
      ended = true;
    }

    result += line[i];
    // Only count printable characters as visible
    const code = line.charCodeAt(i);
    if (code >= 0x20) {
      visCol++;
    }
    i++;
  }

  // Close highlight if we reached end of line before endVisCol
  if (started && !ended) {
    result += "\x1b[27m";
  }

  return result;
}

/**
 * Check if an ANSI sequence is an SGR reset that would clear reverse video.
 * Matches \x1b[0m and \x1b[m (both are full SGR resets).
 */
function isResetSequence(seq: string): boolean {
  return seq === "\x1b[0m" || seq === "\x1b[m";
}

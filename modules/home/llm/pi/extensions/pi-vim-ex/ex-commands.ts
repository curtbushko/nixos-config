/**
 * Ex command system for vim.
 *
 * Supports:
 * - `:q` / `:quit` - Exit
 * - `:q!` / `:quit!` - Force exit
 * - `:w` / `:write` - Save (no-op, Pi auto-saves)
 * - `:wq` / `:x` - Save and exit
 */

import { matchesKey } from "@earendil-works/pi-tui";

export interface ExCommandState {
  /** Current command-line input buffer for : */
  inputBuffer: string;
  /** Whether we're currently in ex command-line mode */
  active: boolean;
  /** Mode to return to after command completes */
  returnMode: "normal" | "visual" | "visual-line";
}

/** Global ex command state */
const exCommandState: ExCommandState = {
  inputBuffer: "",
  active: false,
  returnMode: "normal",
};

export function getExCommandState(): ExCommandState {
  return exCommandState;
}

/**
 * Begin an ex command-line session.
 */
export function beginExCommand(
  returnMode: "normal" | "visual" | "visual-line" = "normal",
): void {
  exCommandState.active = true;
  exCommandState.inputBuffer = "";
  exCommandState.returnMode = returnMode;
}

/**
 * Handle a key during ex command-line input.
 * Returns:
 *   "continue" - keep accepting input
 *   "confirm"  - user pressed Enter, execute the command
 *   "cancel"   - user pressed Escape, cancel
 */
export function handleExCommandInput(data: string): "continue" | "confirm" | "cancel" {
  // Escape or Ctrl+[ → cancel command
  if (matchesKey(data, "escape") || data === "\x1b" || data === "\x1b[") {
    exCommandState.active = false;
    exCommandState.inputBuffer = "";
    return "cancel";
  }

  // Enter → confirm command
  if (data === "\r" || data === "\n") {
    exCommandState.active = false;
    return "confirm";
  }

  // Backspace → delete last character
  if (data === "\x7f" || data === "\b" || matchesKey(data, "backspace")) {
    if (exCommandState.inputBuffer.length > 0) {
      exCommandState.inputBuffer = exCommandState.inputBuffer.slice(0, -1);
    } else {
      // Empty buffer → exit command mode
      exCommandState.active = false;
      return "cancel";
    }
    return "continue";
  }

  // Regular character → append to buffer
  if (data.length === 1 && data >= " " && data <= "~") {
    exCommandState.inputBuffer += data;
    return "continue";
  }

  return "continue";
}

/**
 * Execute an ex command.
 * Returns:
 *   "exit" - should exit the application
 *   "continue" - command executed, continue normally
 *   "error" - unknown command
 */
export function executeExCommand(cmd: string): "exit" | "continue" | "error" {
  const trimmed = cmd.trim();

  switch (trimmed) {
    case "q":
    case "quit":
      // Exit (would need access to editor to check if empty)
      return "exit";

    case "q!":
    case "quit!":
      // Force exit
      return "exit";

    case "w":
    case "write":
      // Pi auto-saves, so this is a no-op
      return "continue";

    case "wq":
    case "x":
      // Save and exit
      return "exit";

    default:
      // Unknown command
      return "error";
  }
}

/**
 * Get the prompt for ex command mode.
 */
export function getExCommandPrompt(): string {
  return ":" + exCommandState.inputBuffer;
}

# Linux Mod/Super is Command; Alt is Option. Raw keycodes preserve - and =.
{
  "cmd - return" = "open -na Ghostty";
  "cmd - t" = "open -na Ghostty";
  # Allow the palette to focus before selecting Applications with Cmd+5.
  "cmd - space" = ''omniwmctl command open-command-palette && sleep 0.2 && skhd -k "cmd - 5"'';
  # OmniWM cannot open the palette directly in Clipboard mode. Press Cmd+3 next.
  "cmd + shift - v" = "omniwmctl command open-command-palette";
  "cmd - tab" = "omniwmctl command toggle-overview";
  "cmd - q" = {
    firefox = null; # Native Cmd+Q quits Firefox rather than closing its window.
    "*" = "omniwmctl command close-focused-window";
  };
  "cmd - m" = "osascript -e 'tell application \"OmniWM\" to quit'";
  "ctrl + alt - 0x75" = "osascript -e 'tell application \"OmniWM\" to quit'";
  "cmd + shift - 0x2C" = ''open -a TextEdit "$HOME/.config/omniwm/KEYBINDINGS.md"'';
  "cmd - left" = "omniwmctl command focus left";
  "cmd - h" = "omniwmctl command focus left";
  "cmd - down" = "omniwmctl command focus down";
  "cmd - j" = "omniwmctl command focus down";
  "cmd - up" = "omniwmctl command focus up";
  "cmd - k" = "omniwmctl command focus up";
  "cmd - right" = "omniwmctl command focus right";
  "cmd - l" = "omniwmctl command focus right";
  "cmd + ctrl - left" = "omniwmctl command move-column left";
  "cmd + ctrl - h" = "omniwmctl command move-column left";
  "cmd + ctrl - right" = "omniwmctl command move-column right";
  "cmd + ctrl - l" = "omniwmctl command move-column right";
  "cmd + ctrl - down" = "omniwmctl command move-window-down";
  "cmd + ctrl - up" = "omniwmctl command move-window-up";
  "cmd + shift - 0x1B" = "omniwmctl command set-window-primary-span -10%";
  "cmd + shift - 0x18" = "omniwmctl command set-window-primary-span +10%";
  "cmd + alt - f" = "omniwmctl command toggle-container-full-primary-span";
  "cmd + alt - right" = "omniwmctl command cycle-size forward";
  "cmd + alt - left" = "omniwmctl command cycle-size forward";
  "cmd + alt - h" = "omniwmctl command cycle-size forward";
  "cmd + alt - l" = "omniwmctl command cycle-size forward";
  "cmd + alt - up" = "omniwmctl command cycle-window-secondary-span forward";
  "cmd + alt - down" = "omniwmctl command cycle-window-secondary-span forward";
}

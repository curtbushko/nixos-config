# Option controls the desktop; Option+Control moves and sizes windows.
# Raw keycodes preserve unshifted - and =.
{
  "alt - return" = "open -a 'Rex Beta'";
  "alt - t" = "open -a 'Rex Beta'";
  # Allow the palette to focus before selecting Applications with Cmd+5.
  "alt - space" = ''omniwmctl command open-command-palette && sleep 0.2 && skhd -k "cmd - 5"'';
  # Select Clipboard after the palette receives focus.
  "alt - v" = ''omniwmctl command open-command-palette && sleep 0.2 && skhd -k "cmd - 3"'';
  "cmd - tab" = "omniwmctl command toggle-overview";
  "alt - tab" = "omniwmctl command toggle-overview";
  "alt - m" = "osascript -e 'tell application \"OmniWM\" to quit'";
  "ctrl + alt - 0x75" = "osascript -e 'tell application \"OmniWM\" to quit'";
  "alt - left" = "omniwmctl command focus left";
  "alt - h" = "omniwmctl command focus left";
  "alt - down" = "omniwmctl command focus down";
  "alt - j" = "omniwmctl command focus down";
  "alt - up" = "omniwmctl command focus up";
  "alt - k" = "omniwmctl command focus up";
  "alt - right" = "omniwmctl command focus right";
  "alt - l" = "omniwmctl command focus right";
  "alt + ctrl - left" = "omniwmctl command move-column left";
  "alt + ctrl - h" = "omniwmctl command move-column left";
  "alt + ctrl - right" = "omniwmctl command move-column right";
  "alt + ctrl - l" = "omniwmctl command move-column right";
  "alt + ctrl - down" = "omniwmctl command move-window-down";
  "alt + ctrl - j" = "omniwmctl command move-window-down";
  "alt + ctrl - up" = "omniwmctl command move-window-up";
  "alt + ctrl - k" = "omniwmctl command move-window-up";
  "alt + ctrl - 0x1B" = "omniwmctl command set-window-primary-span -10%";
  "alt + ctrl - 0x18" = "omniwmctl command set-window-primary-span +10%";
  "alt - f" = "omniwmctl command toggle-container-full-primary-span";
  "alt + ctrl - w" = "omniwmctl command cycle-size forward";
}

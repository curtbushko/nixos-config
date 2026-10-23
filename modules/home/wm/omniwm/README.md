# OmniWM trial on m4-pro

OmniWM 0.7.4 uses niri scrolling layout. **Option/Alt** controls desktop focus;
**Option+Control** moves and sizes windows. **Command/Super** is reserved for
application content, except the familiar Cmd+Tab overview binding. Niri uses the
same desktop shortcuts. skhd supplies aliases and application launch commands.
OmniWM's native hotkeys are disabled to avoid competing defaults.

## Shortcuts

| Keys | Action |
| --- | --- |
| Option+Return / Option+T | Launch/focus Rex Beta (Ghostty on Linux) |
| Option+Space | OmniWM Applications launcher (automatically selects Cmd+5) |
| Option+V | Clipboard history (automatically selects Cmd+3) |
| Cmd+Tab / Option+Tab | Overview |
| Cmd+Q / Cmd+W | Native application Quit / close tab or window (not intercepted) |
| Option+M / Ctrl+Option+Forward Delete | Quit OmniWM, not macOS |
| Option+arrows / Option+H/J/K/L | Focus left/down/up/right |
| Option+Ctrl+Left/Right / Option+Ctrl+H/L | Move whole column |
| Option+Ctrl+Up/Down / Option+Ctrl+K/J | Reorder window within column |
| Option+Ctrl+- / Option+Ctrl+= | Change window width by -/+10% |
| Option+F | Toggle full-width tiled column (Niri: fullscreen) |
| Option+Ctrl+W | Cycle column widths forward: 1/3, 1/2, 2/3 |

No height-preset, shortcut-help, or workspace-selection bindings are installed.
Native media keys retain macOS volume/playback behavior. Arrow aliases are
retained alongside H/J/K/L. The equals key does not require Shift.

Cmd+Tab intentionally replaces native application switching with overview.
Other plain Cmd shortcuts reach the focused application. Terminal mappings are
documented in `modules/home/terminals/README.md`; applications must implement
their own equivalent bindings. Global Option shortcuts override native word
navigation on Option+arrows and special-character entry on the bound letters.
Secure Input can prevent skhd from seeing keys; check terminal Secure Keyboard
Entry if bindings stop.

## Setup

- Homebrew installs `/Applications/OmniWM.app` and `/opt/homebrew/bin/omniwmctl`.
- Grant OmniWM Accessibility and Input Monitoring. Screen Recording is optional
  for overview thumbnails. Click Start OmniWM in its permissions window.
- Grant skhd Accessibility and Input Monitoring as well. In the permission
  picker's Cmd+Shift+G dialog, enter the executable path shown by `command -v
  skhd`. During this trial, Finder reveals the Nix-store executable directly.
  Restart the hotkey agent after granting access.
- Keep **Displays have separate Spaces** enabled (Desktop & Dock > Mission
  Control). Changing it requires logging out and back in.
- Keep one native macOS desktop per display. In Mission Control, hover each
  unused desktop thumbnail and close it with its X; macOS moves its windows to
  a remaining desktop. OmniWM uses only workspace 1.
  Native fullscreen still creates a macOS Space: use Option+F to fill the
  available width while staying tiled, instead of the green fullscreen button/Ctrl+Cmd+F.
- Quit Rectangle while using OmniWM. The m4-pro Home Manager config disables
  Rectangle for future activations; the other Macs are unchanged.
- For multiple displays, use OmniWM's Monitor Setup assistant; Linux DP/HDMI
  connector names and coordinates cannot be copied to macOS. Assign a workspace
  to each display. Edge focus is disabled; keyboard focus still warps the pointer.
- Enable Start at Login in OmniWM only after deciding to keep it. The initial
  trial hotkey agent is loaded from a temporary plist for this login session.
  Home Manager will install it persistently on activation; it does not manage
  OmniWM's startup registration. Enable OmniWM at login before that activation.

The trial uses one workspace (1), with the workspace bar disabled.

The trial uses 6-point inner and outer gaps on all sides (also in managed
fullscreen), keyboard-driven focus with pointer warping, and full-width initial
tiled columns, including Obsidian. Focus-follows-mouse and edge focus are disabled
so hovering edge columns does not scroll the layout. OmniWM's three-finger
column scrolling is disabled.
New windows stay in the scrolling layout rather than entering fullscreen.
The one-third, one-half and two-thirds width presets remain available. OmniWM's
1-point green focus border is enabled. Its outline can mismatch macOS 27's
rounded window corners; native corners are left unchanged.
Picture-in-picture/popout windows float. macOS minimum window sizes can
clamp requested proportions.

## Differences from Linux

OmniWM's palette replaces Vicinae. Clipboard selection sends Cmd+3 after a short
focus delay, just as the application launcher selects Cmd+5. This timing needs
checking on the live desktop; it is not a native direct-to-clipboard API.
The shortcut-help binding is removed in both window managers. Quitting OmniWM
only stops the window manager; unlike Niri's quit action, it never logs you out.
Directional focus can cross monitors, but OmniWM's spatial routing differs
from niri's window-or-monitor actions. Window-height presets are not bound.
Inactive borders, niri's resize shader, corner clipping,
per-app screencast blocking, mpv's Linux output rule, and automatic workspace
back-and-forth are not reproduced. Password-manager screencast protection
must not be assumed to carry over.

## macOS conflict audit

The m4-pro system module auto-hides the Dock (no reserved Dock strip), disables
Stage Manager, and keeps Displays have separate Spaces on. Native desktop
hotkeys 79–82 are disabled while OmniWM is enabled, because this repository
previously mapped them to Cmd+Left/Right and Cmd+Shift+Left/Right. Three- and
four-finger horizontal native Space swipes are disabled along with OmniWM's
column scrolling. Changes to trackpad settings may need logout.
Other Macs retain their native navigation settings.

Spotlight's Cmd+Space bindings and Apple's edge/Option tiling were already
disabled; those settings are compatible. Existing per-app Cmd+H remaps also
remain useful. Only Cmd+Tab remains a global Cmd shortcut; Option-based desktop
bindings replace the previous global Cmd bindings. Cmd+Q is not intercepted,
so applications receive their native Quit shortcut. Secure Keyboard Entry can
still suppress skhd shortcuts. A full system switch was not used for this trial.

## Configuration and validation

`settings.nix` overlays the required 0.7.4 fields in `defaults.json`;
`hotkey-ids.json` contains its required action IDs. These are upstream defaults,
not personal monitor assignments. `bindings.nix` is the shortcut source.
Recheck the schema/action IDs before upgrading to a version that changes them.

Home Manager writes `~/.config/omniwm/settings.toml`, `skhdrc`, and this file.
The TOML is read-only; edit the repository rather than GUI settings. No full
system switch is needed for the initial trial. The original settings are saved
as `~/.config/omniwm/settings.toml.before-omniwm-trial`.

```sh
nix eval --file modules/home/wm/omniwm/tests/check.nix
```

To stop the trial, quit OmniWM, then run:

```sh
launchctl bootout "gui/$(id -u)/org.nix-community.home.omniwm-hotkeys"
open -a Rectangle
```

This restores normal macOS shortcuts. Restore the backed-up TOML if desired.
Before the next activation, set `ns.wm.omniwm.enable = false`, re-enable
`ns.wm.rectangle.enable`, and remove the OmniWM cask if you do not want to keep it.

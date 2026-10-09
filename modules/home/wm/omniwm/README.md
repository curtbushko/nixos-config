# OmniWM trial on m4-pro

OmniWM 0.7.4 uses niri scrolling layout. Linux `Mod`/Super becomes macOS
**Command**, and Linux Alt becomes **Option**. skhd supplies aliases and app
launch commands because OmniWM accepts only one native shortcut per action.
OmniWM's native hotkeys are disabled to avoid competing defaults.

## Shortcuts

| Keys | Action |
| --- | --- |
| Cmd+Return / Cmd+T | New Ghostty instance |
| Cmd+Space | OmniWM Applications launcher (automatically selects Cmd+5) |
| Cmd+Shift+V | Command palette; press Cmd+3 for clipboard history |
| Cmd+Tab | Overview |
| Cmd+Shift+/ | Open this cheat sheet |
| Cmd+Q | Quit Firefox; close the focused window in other applications |
| Cmd+M / Ctrl+Option+Forward Delete | Quit OmniWM, not macOS |
| Cmd+arrows / Cmd+H/J/K/L | Focus left/down/up/right |
| Cmd+Ctrl+Left/Right / Cmd+Ctrl+H/L | Move whole column |
| Cmd+Ctrl+Up/Down | Reorder window within column |
| Cmd+Shift+- / Cmd+Shift+= | Change window width by -/+10% |
| Cmd+Option+F | Toggle full-width tiled column (not fullscreen) |
| Cmd+Option+Left/Right/H/L | Cycle column widths forward: 1/3, 1/2, 2/3 |
| Cmd+Option+Up/Down | Cycle window height presets forward |

Both directions cycle forward, just like the source niri configuration.
Native media keys retain macOS volume/playback behavior.

**These global bindings replace normal macOS Cmd+H, Cmd+J, Cmd+K, Cmd+L,
Cmd+T, Cmd+Q (except in Firefox), Cmd+M, Cmd+Space and Cmd+Tab behavior.** Disable the Spotlight
Cmd+Space shortcut in System Settings > Keyboard > Keyboard Shortcuts >
Spotlight if it competes with the launcher. Secure Input in an app can prevent
skhd from seeing keys; check terminal Secure Keyboard Entry if bindings stop.

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
  Native fullscreen still creates a macOS Space: use Cmd+Option+F to fill the
  available width while staying tiled, instead of the green fullscreen button/Ctrl+Cmd+F.
- Quit Rectangle while using OmniWM. The m4-pro Home Manager config disables
  Rectangle for future activations; the other Macs are unchanged.
- For multiple displays, use OmniWM's Monitor Setup assistant; Linux DP/HDMI
  connector names and coordinates cannot be copied to macOS. Assign a workspace
  to each display and enable edge focus and mouse warp.
- Enable Start at Login in OmniWM only after deciding to keep it. The initial
  trial hotkey agent is loaded from a temporary plist for this login session.
  Home Manager will install it persistently on activation; it does not manage
  OmniWM's startup registration. Enable OmniWM at login before that activation.

The trial uses one workspace (1), with the workspace bar disabled.

The trial uses 6-point inner and outer gaps on all sides (also in managed
fullscreen), focus-follows-mouse,
pointer warping, and full-width initial tiled columns, including Obsidian.
New windows stay in the scrolling layout rather than entering fullscreen.
The one-third, one-half and two-thirds width presets remain available. OmniWM's
1-point green focus border is enabled. Its outline can mismatch macOS 27's
rounded window corners; native corners are left unchanged.
Picture-in-picture/popout windows float. macOS minimum window sizes can
clamp requested proportions.

## Differences from Linux

OmniWM's palette replaces Vicinae. Clipboard needs a second Cmd+3 keystroke.
OmniWM exposes no exact niri hotkey-overlay action, so the help shortcut opens
this file. Quit only stops the window manager; it never logs you out.
Directional focus can cross monitors, but OmniWM's spatial routing differs
from niri's window-or-monitor actions. Window-height presets use OmniWM's
implementation. Inactive borders, niri's resize shader, corner clipping,
per-app screencast blocking, mpv's Linux output rule, and automatic workspace
back-and-forth are not reproduced. Password-manager screencast protection
must not be assumed to carry over.

## macOS conflict audit

The m4-pro system module auto-hides the Dock (no reserved Dock strip), disables
Stage Manager, and keeps Displays have separate Spaces on. Native desktop
hotkeys 79–82 are disabled while OmniWM is enabled, because this repository
previously mapped them to Cmd+Left/Right and Cmd+Shift+Left/Right. Three- and
four-finger horizontal native Space swipes are disabled so they do not compete
with OmniWM's column scrolling. Changes to trackpad settings may need logout.
Other Macs retain their native navigation settings.

Spotlight's Cmd+Space bindings and Apple's edge/Option tiling were already
disabled; those settings are compatible. Existing per-app Cmd+H remaps also
remain useful. Cmd+Tab, Cmd+Q, Cmd+M and the other documented global bindings
intentionally override ordinary app/macOS behavior, except Firefox's native
Cmd+Q quit action. Secure Keyboard Entry can
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

# macOS Performance Optimization Module

This module disables unnecessary macOS background services to reduce CPU usage, heat, and battery drain.

## What Gets Disabled

### Intelligence & AI Services
- **Siri**: All Siri-related daemons and agents
- **Intelligence Platform**: Apple Intelligence, Spotlight suggestions, predictive features
- **Suggestions**: Proactive suggestions across the system
- **Knowledge Services**: Background context and knowledge building

### Continuity Services
- **Handoff**: Cross-device app handoff
- **Universal Control**: Cross-device mouse/keyboard sharing
- **AirDrop**: ✅ KEPT (still functional)

### Safari Services
- **Bookmark Sync**: Safari bookmark synchronization
- **History Sync**: Safari history synchronization

### App Services
- **Game Center**: All gaming services
- **Maps**: Background map updates and sync
- **News**: News feed and content suggestions
- **Podcasts**: Background podcast services

### Media Analysis
- **Photo Analysis**: Face detection, scene analysis, memories (high CPU)
- **Media Analysis**: General media content analysis

### Background Services
- **App Store**: Automatic app updates
- **Screen Time**: Usage tracking
- **Shazam**: Background music recognition
- **Generative AI**: Image Playground and other generative features

## Expected Performance Impact

- **CPU Usage**: 10-30% reduction in idle CPU usage
- **Heat**: Significant reduction in heat generation
- **Battery**: Improved battery life on laptops
- **RAM**: ~500MB-1GB freed

## How It Works

This module uses **multiple layered approaches** to disable services, following nix-darwin best practices:

### 1. Declarative System Preferences (system.defaults.CustomUserPreferences)
Uses nix-darwin's declarative configuration for macOS preferences:
- **Siri & Assistant**: Disables Siri menu bar, assistant support, search query sharing
- **Apple Intelligence**: Opts out of all Apple Intelligence features and reporting
- **Spotlight**: Disables AI-powered suggestions
- **Privacy**: Disables advertising tracking, personalized ads, crash reporter dialogs
- **Safari**: Disables universal search (web search from address bar)

This is the **preferred approach** - cleaner and more maintainable than shell scripts.

### 2. Service Disabling (launchctl disable)
Prevents services from loading at boot via launchd's disabled services database (`/var/db/com.apple.xpc.launchd/disabled.plist`).

### 3. Plist Unloading (launchctl unload -w)
Unloads service plists with the `-w` flag to write the disabled state persistently.

### 4. Process Termination (killall)
Immediately kills any running processes to free resources.

**Note**: Methods 2-4 must use activation scripts since nix-darwin's `launchd.user.agents` is for *creating* agents, not disabling Apple's system services.

### Known Limitations

**Some XPC services may auto-restart** when triggered by other system components. This is a macOS design limitation - according to [The Eclectic Light Company](https://eclecticlight.co/2026/01/16/can-you-disable-spotlight-and-siri-in-macos-tahoe/), it's not possible to completely disable Siri/Spotlight without disabling System Integrity Protection (SIP).

Services that may still appear occasionally:
- `siriinferenced` (on-demand XPC service)
- `SiriSuggestionsBookkeepingService` (XPC service)
- `IntelligencePlatformComputeService` (XPC service)
- `visualintelligenced` (on-demand service)

These use minimal CPU when idle and are automatically killed when no longer needed.

## Installation

This module is auto-discovered by snowfall-lib. To enable it:

```nix
# In systems/aarch64-darwin/m4-pro/default.nix
{
  imports = [
    # ... other imports
  ];

  # The performance module is automatically imported
  # No additional configuration needed
}
```

After adding, rebuild your system:

```bash
cd ~/workspace/github.com/curtbushko/nixos-config
darwin-rebuild switch --flake .#m4-pro
```

## Reverting Changes

If you need to re-enable services:

1. **Disable this module**: Remove it from your imports or comment out in the module
2. **Rebuild**: Run `darwin-rebuild switch --flake .#m4-pro`
3. **Manual re-enable** (if needed):

```bash
# Re-enable specific services
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.apple.assistantd.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.apple.suggestd.plist

# Or reboot to restore all system defaults
```

## Caveats

- **Siri**: Voice commands will not work
- **Spotlight Suggestions**: No web search in Spotlight
- **Handoff**: Cannot continue work from iPhone/iPad
- **Universal Control**: Cannot use Mac keyboard/mouse on iPad
- **Photo Memories**: No automatic photo collections
- **App Auto-Updates**: Manual updates required via App Store

## Compatibility

- **macOS**: Sequoia (15.x) and newer
- **nix-darwin**: Compatible with nix-darwin 5+
- **System**: M-series Macs (tested on M4 Pro)

## Monitoring

To verify services are disabled:

```bash
# Check if Siri is disabled
launchctl list | grep -i siri

# Check if intelligence services are disabled
launchctl list | grep -i intelligence

# Monitor CPU usage
top -l 1 -n 10 -o cpu
```

## Troubleshooting

### Services Re-Enable After Update

macOS updates may re-enable some services. After a system update:

```bash
darwin-rebuild switch --flake .#m4-pro
```

### System Feels Sluggish

Some services (like corespotlightd) are required for system functionality. This module only disables non-essential services. If you experience issues, check Activity Monitor for other CPU-intensive processes.

### Need Specific Service

If you need a specific disabled service, you can manually enable it:

```bash
# Example: Re-enable Siri
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.apple.assistantd.plist
```

Or create a custom override in your system config.

## Additional Manual Disabling (If Needed)

If you want even more aggressive control, you can manually disable features via System Settings:

1. **System Settings → Apple Intelligence & Siri** → Toggle off "Apple Intelligence"
2. **System Settings → Siri & Spotlight** → Disable "Siri Suggestions"
3. **System Settings → Screen Time → Content & Privacy → Intelligence & Siri** → Block specific features

## References

This module uses techniques documented in:

### Nix-Darwin Configuration
- [nix-darwin system.defaults - MyNixOS](https://mynixos.com/nix-darwin/options/system.defaults)
- [heywoodlh's darwin-defaults.nix](https://github.com/heywoodlh/nixos-configs/blob/c1c7a16778cc93b3add7b43167e18c05db5ad78a/home/modules/darwin-defaults.nix) - Privacy-focused macOS settings
- [launchd.user.agents - MyNixOS](https://mynixos.com/nix-darwin/options/launchd.user.agents.%3Cname%3E)

### macOS Service Disabling
- [How to disable Apple Intelligence features on macOS - Tom's Guide](https://www.tomsguide.com/ai/apple-intelligence/how-to-disable-apple-intelligence-features-on-macos)
- [Disable Siri Completely On MacOS Using Terminal Commands - Undercode Testing](https://undercodetesting.com/disable-siri-completely-on-macos-using-terminal-commands/)
- [Disabling photoanalysisd - GitHub Gist](https://gist.github.com/huksley/564be2c903312bcee7dffe415d128f90)
- [A launchd Tutorial](https://launchd.info/)
- [Can you disable Spotlight and Siri in macOS Tahoe? - The Eclectic Light Company](https://eclecticlight.co/2026/01/16/can-you-disable-spotlight-and-siri-in-macos-tahoe/)
- [Block access to Apple Intelligence features in Screen Time - Apple Support](https://support.apple.com/guide/mac-help/mchlb2e44f94/mac)

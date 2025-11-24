{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.terminals;
  # Helper function to convert hex color to RGBA values
  hexToRGBA = hex: alpha:
    let
      r = builtins.fromTOML "v=0x${builtins.substring 1 2 hex}";
      g = builtins.fromTOML "v=0x${builtins.substring 3 2 hex}";
      b = builtins.fromTOML "v=0x${builtins.substring 5 2 hex}";
    in "${toString r.v},${toString g.v},${toString b.v},${toString alpha}";
in {
  config = mkIf cfg.enable {
    xdg.configFile."ghostty/config" = {
      text = let
        base00 = "#${config.lib.stylix.colors.base00}";
        base01 = "#${config.lib.stylix.colors.base01}";
        base02 = "#${config.lib.stylix.colors.base02}";
        base03 = "#${config.lib.stylix.colors.base03}";
        base04 = "#${config.lib.stylix.colors.base04}";
        base05 = "#${config.lib.stylix.colors.base05}";
        base06 = "#${config.lib.stylix.colors.base06}";
        base07 = "#${config.lib.stylix.colors.base07}";
        base08 = "#${config.lib.stylix.colors.base08}";
        base09 = "#${config.lib.stylix.colors.base09}";
        base0A = "#${config.lib.stylix.colors.base0A}";
        base0B = "#${config.lib.stylix.colors.base0B}";
        base0C = "#${config.lib.stylix.colors.base0C}";
        base0D = "#${config.lib.stylix.colors.base0D}";
        base0E = "#${config.lib.stylix.colors.base0E}";
        base0F = "#${config.lib.stylix.colors.base0F}";
        isLinux = pkgs.stdenv.isLinux;
        isDarwin = pkgs.stdenv.isDarwin;
      in ''
        auto-update = off
        font-size = 10
        font-family = Intel One Mono
        font-style = medium
        font-feature = "ss01"
        #adjust-cell-width = 1%
        #adjust-cell-height = 1%
        background-opacity = .95
        background-blur-radius = 20
        macos-non-native-fullscreen = visible-menu
        macos-option-as-alt = left
        macos-titlebar-style = hidden
        gtk-titlebar = false
        mouse-hide-while-typing = true
        shell-integration = zsh
        shell-integration-features = no-cursor,ssh-env,ssh-terminfo
        window-padding-x = 0
        window-padding-y = 0
        window-save-state = always
        confirm-close-surface = false
        cursor-style = block
        cursor-style-blink = true
        custom-shader = "shaders/blaze.glsl"
        custom-shader = "shaders/glow.glsl"
        custom-shader-animation = true

        # Keybinds to match macOS since this is a VM
        keybind = super+c=copy_to_clipboard
        keybind = super+v=paste_from_clipboard
        keybind = super+equal=increase_font_size:1
        keybind = super+minus=decrease_font_size:1
        keybind = super+zero=reset_font_size
        keybind = super+q=quit
        keybind = super+shift+comma=reload_config
        keybind = super+k=clear_screen
        #keybind = super+n=new_window
        #keybind = super+w=close_surface
        #keybind = super+shift+w=close_window
        #keybind = super+t=new_tab
        #keybind = super+shift+left_bracket=previous_tab
        #keybind = super+shift+right_bracket=next_tab
        #keybind = super+d=new_split:right
        #keybind = super+shift+d=new_split:down
        #keybind = super+right_bracket=goto_split:next
        #keybind = super+left_bracket=goto_split:previous
        # Unbind these keys as they are the default in linux
        keybind = alt+one=unbind
        keybind = alt+two=unbind
        keybind = alt+three=unbind
        keybind = alt+four=unbind
        keybind = alt+five=unbind
        keybind = alt+six=unbind
        keybind = alt+seven=unbind
        keybind = alt+eight=unbind
        keybind = alt+nine=unbind
        # fix for claude-code
        keybind = shift+enter=text:\n
        # foreground (fg/bg)
        foreground = ${base05}
        background = ${base01}
        # black (bg_dark/red)
        palette = 0=${base00}
        palette = 8=${base02}
        # red (red/organge)
        palette = 1=${base08}
        palette = 9=${base09}
        # green (dark3/magenta)
        palette = 2=${base0B}
        palette = 10=${base0F}
        # yellow (
        palette = 3=${base0A}
        palette = 11=${base04}
        # blue
        palette = 4=${base0C}
        palette = 12=${base0D}
        # purple
        palette = 5=${base0E}
        palette = 13=${base03}
        # aqua
        palette = 6=${base0B}
        palette = 14=${base0F}
        # white
        #palette = 7=${base05}
        #palette = 15=${base06}
      ''
      + (lib.optionalString isLinux ''
        window-decoration = true
        app-notifications = false
      ''
      )
      + (lib.optionalString isDarwin ''
        window-decoration = true
        app-notifications = true
      ''
      );
    };
    xdg.configFile."ghostty/shaders/blaze.glsl" = {
      text = let
        base01 = "#${config.lib.stylix.colors.base01}";
        base0C = "#${config.lib.stylix.colors.base0C}";
        base0D = "#${config.lib.stylix.colors.base0D}";
      in ''
        float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
        {
            vec2 d = abs(p - xy) - b;
            return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
        }

        // Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
        // Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching

        float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
            vec2 e = b - a;
            vec2 w = p - a;
            vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
            float segd = dot(p - proj, p - proj);
            d = min(d, segd);

            float c0 = step(0.0, p.y - a.y);
            float c1 = 1.0 - step(0.0, p.y - b.y);
            float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
            float allCond = c0 * c1 * c2;
            float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
            float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
            s *= flip;
            return d;
        }

        float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
            float s = 1.0;
            float d = dot(p - v0, p - v0);

            d = seg(p, v0, v3, s, d);
            d = seg(p, v1, v0, s, d);
            d = seg(p, v2, v1, s, d);
            d = seg(p, v3, v2, s, d);

            return s * sqrt(d);
        }

        vec2 norm(vec2 value, float isPosition) {
            return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
        }

        float antialising(float distance) {
            return 1. - smoothstep(0., norm(vec2(2., 2.), 0.).x, distance);
        }

        float determineStartVertexFactor(vec2 c, vec2 p) {
            // Conditions using step
            float condition1 = step(p.x, c.x) * step(c.y, p.y); // c.x < p.x && c.y > p.y
            float condition2 = step(c.x, p.x) * step(p.y, c.y); // c.x > p.x && c.y < p.y

            // If neither condition is met, return 1 (else case)
            return 1.0 - max(condition1, condition2);
        }

        float determineStartVertexFactor2(vec2 c, vec2 p) {
            // Conditions using step
            float condition1 = step(p.x, c.x) * step(c.y, p.y); // c.x < p.x && c.y > p.y
            float condition2 = step(c.x, p.x) * step(p.y, c.y); // c.x > p.x && c.y < p.y

            // If neither condition is met, return 1 (else case)
            return 1.0 - max(condition1, condition2);
        }

        vec2 getRectangleCenter(vec4 rectangle) {
            return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
        }
        float ease(float x) {
            return pow(1.0 - x, 3.0);
        }

        const vec4 TRAIL_COLOR = vec4(${hexToRGBA base0C 0.6}) / vec4(255.0,255.0,255.0,255.0); //stylix driven
        const vec4 TRAIL_COLOR_ACCENT = vec4(${hexToRGBA base01 0.5}) / vec4(255.0,255.0,255.0,255.0); //stylix driven

        const float DURATION = 0.2; //IN SECONDS

        void mainImage(out vec4 fragColor, in vec2 fragCoord)
        {
            fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
            // Normalization for fragCoord to a space of -1 to 1;
            vec2 vu = norm(fragCoord, 1.);
            vec2 offsetFactor = vec2(-.5, 0.5);

            // Normalization for cursor position and size;
            // cursor xy has the postion in a space of -1 to 1;
            // zw has the width and height
            vec4 currentCursor = vec4(norm(iCurrentCursor.xy, 1.), norm(iCurrentCursor.zw, 0.));
            vec4 previousCursor = vec4(norm(iPreviousCursor.xy, 1.), norm(iPreviousCursor.zw, 0.));

            vec2 centerCC = getRectangleCenter(currentCursor);
            vec2 centerCP = getRectangleCenter(previousCursor);
            // When drawing a parellelogram between cursors for the trail i need to determine where to start at the top-left or top-right vertex of the cursor
            float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
            float invertedVertexFactor = 1.0 - vertexFactor;

            // Set every vertex of my parellogram
            vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
            vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
            vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
            vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);

            float sdfCurrentCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
            float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);

            float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
            float easedProgress = ease(progress);
            // Distance between cursors determine the total length of the parallelogram;
            float lineLength = distance(centerCC, centerCP);

            vec4 newColor = vec4(fragColor);
            // Compute fade factor based on distance along the trail
            float fadeFactor = 1.0 - smoothstep(lineLength, sdfCurrentCursor, easedProgress * lineLength);

            float mod = .007;
            //trailblaze
            vec4 trail = mix(TRAIL_COLOR_ACCENT, fragColor, 1. - smoothstep(0., sdfTrail + mod, 0.007));
            trail = mix(TRAIL_COLOR, trail, 1. - smoothstep(0., sdfTrail + mod, 0.006));
            trail = mix(trail, TRAIL_COLOR, step(sdfTrail + mod, 0.));
            //cursorblaze
            trail = mix(TRAIL_COLOR_ACCENT, trail, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
            trail = mix(TRAIL_COLOR, trail, 1. - smoothstep(0., sdfCurrentCursor + .002, 0.004));
            fragColor = mix(trail, fragColor, 1. - smoothstep(0., sdfCurrentCursor, easedProgress * lineLength));
        }
      '';
    };
    xdg.configFile."ghostty/shaders/glow.glsl" = {
      text = ''
        void mainImage(out vec4 fragColor, in vec2 fragCoord) {
            vec2 uv = fragCoord/iResolution.xy;

            // Base color from terminal
            vec3 color = texture(iChannel0, uv).rgb;

            // Add bloom/glow
            float bloom = 0.04;
            vec3 glow = vec3(0.0);
            for(float i = 0.0; i < 4.0; i++) {
                vec2 offset = vec2(i) / iResolution.xy;
                glow += texture(iChannel0, uv + offset).rgb;
                glow += texture(iChannel0, uv - offset).rgb;
            }

            // Combine glow with original color
            color += glow * bloom;
 
            fragColor = vec4(color, 1.0);
        }
      '';
    };
  };
}

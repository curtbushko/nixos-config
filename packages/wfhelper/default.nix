{
  lib,
  fetchurl,
  appimageTools,
  stdenvNoCC,
  makeWrapper,
  patchelf,
}: let
  pname = "wfhelper";
  version = "2.1.1";
  src = fetchurl {
    url = "https://github.com/WFHelper/WFHelper/releases/download/v${version}/WFHelper-${version}.AppImage";
    hash = "sha256-04lf525fLcWC9yI6Bw4PZn0MUZNUfKrypvVqfoCvRdM=";
  };
  contents = appimageTools.extract {inherit pname version src;};
  # Reuse the exact appimageTools dependency tree, not its Bubblewrap launcher.
  # A sibling user namespace prevents WFHelper inspecting the Proton process.
  runtime = (appimageTools.wrapType2 {inherit pname version src;}).fhsenv;
in
  stdenvNoCC.mkDerivation {
    inherit pname version;
    src = contents;
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    # Preserve upstream native addons and libraries: no stripping/auto-patching.
    dontFixup = true;
    nativeBuildInputs = [makeWrapper patchelf];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/libexec/wfhelper" "$out/bin"
      cp -r "$src/." "$out/libexec/wfhelper/"
      chmod -R u+w "$out/libexec/wfhelper"

      # Change only the executable interpreter. Retain upstream $ORIGIN RPATHs
      # and every bundled shared library, including GTK and OCR/native addons.
      for executable in wfhelper chrome_crashpad_handler chrome-sandbox; do
        patchelf --set-interpreter "${runtime}/usr/lib64/ld-linux-x86-64.so.2" \
          "$out/libexec/wfhelper/$executable"
      done

      # Call the actual application directly. AppRun's automatic --no-sandbox
      # fallback is deliberately not used; Chromium's default sandbox remains.
      makeWrapper "$out/libexec/wfhelper/wfhelper" "$out/bin/wfhelper" \
        --prefix LD_LIBRARY_PATH : "$out/libexec/wfhelper/usr/lib:${runtime}/usr/lib64" \
        --prefix PATH : "${runtime}/usr/bin:$out/libexec/wfhelper" \
        --prefix XDG_DATA_DIRS : "$out/libexec/wfhelper/usr/share:${runtime}/usr/share" \
        --set GSETTINGS_SCHEMA_DIR "${runtime}/usr/share/glib-2.0/schemas"

      install -Dm444 "$src/wfhelper.desktop" "$out/share/applications/wfhelper.desktop"
      substituteInPlace "$out/share/applications/wfhelper.desktop" \
        --replace-fail 'Exec=AppRun' "Exec=$out/bin/wfhelper"
      cp -r "$src/usr/share/icons" "$out/share/icons"
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      # Existing runtime only: do not start the GUI or inventory acquisition.
      ELECTRON_RUN_AS_NODE=1 "$out/bin/wfhelper" -e \
        'if (!process.versions.electron) process.exit(1)'
      runHook postInstallCheck
    '';

    meta = {
      description = "Warframe companion for inventory, relic rewards, and market prices";
      homepage = "https://github.com/WFHelper/WFHelper";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "wfhelper";
    };
  }

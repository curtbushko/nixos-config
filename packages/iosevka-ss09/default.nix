{
  lib,
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "iosevka-ss09";
  version = "34.4.0";

  src = fetchzip {
    url = "https://github.com/be5invis/Iosevka/releases/download/v${version}/PkgTTF-IosevkaSS09-${version}.zip";
    hash = "sha256-vGUxEnZtIU7+ZjbfIZAp1Tl8JwSCy+rBqqyBysqX5g4=";
    stripRoot = false;
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  doCheck = false;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -m444 -Dt $out/share/fonts/truetype *.ttf
    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/be5invis/Iosevka";
    description = "Iosevka SS09 - Source Code Pro Style variant";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}

{
  buildNpmPackage,
  importNpmLock,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage {
  pname = "kb-tasknotes-tools";
  version = "1.0.0";
  src = ./.;
  nodejs = nodejs_22;

  npmDeps = importNpmLock {
    npmRoot = ./.;
  };
  npmConfigHook = importNpmLock.npmConfigHook;
  dontNpmBuild = true;
  npmFlags = ["--ignore-scripts"];
  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/tasknotes-tools" "$out/bin"
    cp -r node_modules "$out/lib/tasknotes-tools/"
    makeWrapper ${nodejs_22}/bin/node "$out/bin/kb-node" \
      --set NODE_PATH "$out/lib/tasknotes-tools/node_modules"
    makeWrapper ${nodejs_22}/bin/node "$out/bin/mtn" \
      --add-flags "$out/lib/tasknotes-tools/node_modules/mdbase-tasknotes/dist/cli.js"
    makeWrapper ${nodejs_22}/bin/node "$out/bin/tn" \
      --add-flags "$out/lib/tasknotes-tools/node_modules/tasknotes-cli/bin/tn"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    env -u NODE_PATH "$out/bin/kb-node" -e "require('yaml'); require('zod');"
    "$out/bin/mtn" --version
    "$out/bin/tn" --help > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Pinned Node runtime, offline mtn and API-backed tn CLIs for TaskNotes";
    mainProgram = "kb-node";
  };
}

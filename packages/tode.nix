{ lib
, stdenvNoCC
, fetchurl
, makeWrapper
}:

# Terminal Code ("tode") — VS Code rendered into a kitty-graphics terminal.
#
# Upstream ships one artifact per platform: a ~130MB tree containing its own
# compiled JS, a vendored terminal-browser, and a full signed Electron.app.
# There is nothing to compile, so this is an unpack-and-repair job. Three
# things upstream does at runtime have to be undone, because all three assume
# the install root is writable and ours is /nix/store:
#
#   1. `writeLauncher()` rewrites vendor/terminal-browser/bin/terminal-browser
#      on *every* launch to bake in XDG paths. Patched to return the launcher
#      we pre-write here, which derives the same paths from $HOME at runtime.
#   2. `--upgrade` / `--uninstall` replace or delete the install root. Patched
#      to fail loudly and point at this flake instead.
#   3. code-server is downloaded to ~/.local/share on first launch. Vendored
#      here at the version tode pins, via the TODE_CODE_SERVER escape hatch
#      upstream already honours.
#
# Darwin only for now: the Linux artifact is a bare Electron layout that needs
# autoPatchelf or an FHS env, which is a separate piece of work.

let
  version = "0.2.0";

  # Set by dist/codeserver/vendored.js — the workbench tode injects into is
  # version-specific, so this must be bumped in lockstep with tode itself.
  # Upstream records the asset's sha256 there too; it is the same hash below.
  codeServerVersion = "4.132.0";

  sources = {
    aarch64-darwin = {
      tode = {
        url = "https://github.com/zenbu-labs/terminal-code/releases/download/v${version}/tode-darwin-arm64.tar.gz";
        hash = "sha256-p9hov1gVpsHshoAYIN0+RqipN+EY5KShbH/pOqbC8b4=";
      };
      codeServer = {
        url = "https://github.com/coder/code-server/releases/download/v${codeServerVersion}/code-server-${codeServerVersion}-macos-arm64.tar.gz";
        hash = "sha256-RJgU9mN/qvm2hUT3vOVg9exQDeaIgV1cf5r6elFXeZI=";
      };
    };
  };

  system = stdenvNoCC.hostPlatform.system;
  source = sources.${system} or (throw "tode: no prebuilt release for ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "tode";
  inherit version;

  srcs = [
    (fetchurl { inherit (source.tode) url hash; })
    (fetchurl { inherit (source.codeServer) url hash; })
  ];

  nativeBuildInputs = [ makeWrapper ];

  # Unpacked by hand in installPhase: two tarballs, two destinations.
  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  # The Electron.app carries a Developer ID signature. Stripping, shebang
  # patching or re-signing any Mach-O inside it invalidates that signature and
  # macOS then refuses to launch the helper. Leave the tree byte-identical.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    todeSrc=$(echo $srcs | tr ' ' '\n' | grep tode-darwin)
    codeServerSrc=$(echo $srcs | tr ' ' '\n' | grep code-server)

    mkdir -p "$out/lib"
    tar -xzf "$todeSrc" -C "$out/lib"
    mkdir -p "$out/lib/code-server"
    tar -xzf "$codeServerSrc" --strip-components 1 -C "$out/lib/code-server"

    app="$out/lib/tode"

    # (1) Stop the per-launch launcher rewrite. The vendored terminal-browser
    # already matches PINNED_VERSION, so resolveRuntime() takes the "vendored"
    # branch and this is the only writeLauncher call that can fire.
    substituteInPlace "$app/dist/runtime/release.js" \
      --replace-fail \
        'return { bin: writeLauncher(VENDORED), root: VENDORED, version, source: "vendored" };' \
        'return { bin: node_path_1.default.join(VENDORED, "bin", "terminal-browser"), root: VENDORED, version, source: "vendored" };'

    # …and hand it a launcher that does what writeLauncher would have, except
    # resolving $HOME when it runs rather than when it was written. Keeps the
    # browser's Chromium profile out of the user's real XDG dirs, same as
    # upstream. mkdir here because writeLauncher used to create these.
    substituteInPlace "$app/vendor/terminal-browser/bin/terminal-browser" \
      --replace-fail \
        'export ELECTRON_RUN_AS_NODE=1' \
        'export ELECTRON_RUN_AS_NODE=1
tb_data="''${XDG_DATA_HOME:-}";  case "$tb_data"  in /*) ;; *) tb_data="$HOME/.local/share" ;; esac
tb_state="''${XDG_STATE_HOME:-}"; case "$tb_state" in /*) ;; *) tb_state="$HOME/.local/state" ;; esac
tb_cache="''${XDG_CACHE_HOME:-}"; case "$tb_cache" in /*) ;; *) tb_cache="$HOME/.cache" ;; esac
export XDG_DATA_HOME="''${TODE_BROWSER_DATA:-$tb_data/tode/browser/share}"
export XDG_STATE_HOME="''${TODE_BROWSER_STATE:-$tb_state/tode/browser/state}"
export XDG_CACHE_HOME="''${TODE_BROWSER_CACHE:-$tb_cache/tode/browser}"
export TERMINAL_BROWSER_APPDATA="''${TODE_BROWSER_APPDATA:-$tb_data/tode/browser/chromium}"
if [ -n "''${TODE_BROWSER_RUN:-}" ]; then export XDG_RUNTIME_DIR="$TODE_BROWSER_RUN"; fi
mkdir -p "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$TERMINAL_BROWSER_APPDATA"'

    # (2) Self-mutation belongs to the Nix generation now. `--upgrade --check`
    # still works: it only reports whether a newer release exists, which is
    # exactly what you want before bumping the pin above.
    #
    # The braces around the --upgrade replacement are load-bearing: main.js
    # dispatches with brace-less `if (args[0] === "--upgrade") return ...;`, so
    # splicing two statements in without a block leaves the `return
    # upgradeCommand(...)` dangling *outside* the condition — every tode
    # invocation would then run an upgrade check instead of opening the editor.
    substituteInPlace "$app/dist/main.js" \
      --replace-fail \
        'return upgradeCommand(args.slice(1));' \
        '{ if (!args.slice(1).includes("--check")) throw new Error("this tode is managed by Nix — bump packages/tode.nix in CodeJoule/nixpkgs and rebuild"); return upgradeCommand(args.slice(1)); }' \
      --replace-fail \
        'return (0, uninstall_1.uninstallCommand)(args.slice(1));' \
        'throw new Error("this tode is managed by Nix — remove it from modules/packages.nix and rebuild");'

    # Upstream's own bin/tode defaults TODE_INSTALL_ROOT to ~/.local/lib/tode,
    # which is not where we put it. Ship our own entry point instead of
    # wrapping theirs; it is a six-line shim either way.
    mkdir -p "$out/bin"
    cat > "$out/bin/tode" <<'SHIM'
#!/bin/sh
ROOT="@app@"
CONTENTS="$ROOT/vendor/terminal-browser/electron/terminal-browser.app/Contents"
HELPER="$CONTENTS/Frameworks/Electron Helper.app/Contents/MacOS/Electron Helper"
[ -x "$HELPER" ] || HELPER="$CONTENTS/MacOS/terminal-browser"
export TODE_INSTALL_ROOT="$ROOT"
export TODE_CODE_SERVER="''${TODE_CODE_SERVER:-@codeServer@}"
export ELECTRON_RUN_AS_NODE=1
exec "$HELPER" "$ROOT/dist/main.js" "$@"
SHIM
    substituteInPlace "$out/bin/tode" \
      --replace-fail '@app@' "$app" \
      --replace-fail '@codeServer@' "$out/lib/code-server/bin/code-server"
    chmod 755 "$out/bin/tode"

    runHook postInstall
  '';

  meta = {
    description = "VS Code rendered inside a kitty-graphics terminal";
    longDescription = ''
      Terminal Code runs code-server in a headless Chromium and streams the
      rendered frames into the terminal using the kitty graphics protocol.
      It therefore requires a terminal that implements that protocol —
      Ghostty, kitty, WezTerm or Konsole. It will not work over mosh, whose
      state-sync model discards graphics escape sequences.
    '';
    homepage = "https://terminal-code.com/";
    downloadPage = "https://github.com/zenbu-labs/terminal-code/releases";
    license = lib.licenses.mit;
    mainProgram = "tode";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

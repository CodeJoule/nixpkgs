{ lib
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, libgcc
}:

let
  version = "0.2026.08.05.09.03.stable_01";

  sources = {
    aarch64-darwin = {
      url = "https://releases.warp.dev/stable/v${version}/tui/macos/aarch64/warp-tui-stable-macos-aarch64.tar.gz";
      hash = "sha256-xdriuCeHCJJk3kv+NvZvnHtMnb0Aa8uYVdfwrfjLGHc=";
    };
    x86_64-darwin = {
      url = "https://releases.warp.dev/stable/v${version}/tui/macos/x86_64/warp-tui-stable-macos-x86_64.tar.gz";
      hash = "sha256-nZcQb8HQBk65ev8rHGJbUjYSfXBUo5HfGQFO31JAxqc=";
    };
    aarch64-linux = {
      url = "https://releases.warp.dev/stable/v${version}/tui/linux/aarch64/warp-tui-stable-linux-aarch64.tar.gz";
      hash = "sha256-9qXXwuw1fvGzkuny4kWgXNOJ4ePKAlwdYAhFXs/X+Xo=";
    };
    x86_64-linux = {
      url = "https://releases.warp.dev/stable/v${version}/tui/linux/x86_64/warp-tui-stable-linux-x86_64.tar.gz";
      hash = "sha256-5rnKxkR/vX0UcwD9WC/4jHr+c1nxfxp0r93kePvND1w=";
    };
  };

  system = stdenvNoCC.hostPlatform.system;
  source = sources.${system} or (throw "warp-agent-cli: unsupported system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "warp-agent-cli";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  # Upstream ships a prebuilt, code-signed (Darwin) / dynamically linked
  # (Linux) binary — nothing to compile here.
  sourceRoot = ".";
  dontBuild = true;
  dontConfigure = true;
  # Stripping or re-signing would invalidate Warp's Developer ID signature
  # on Darwin; on Linux the tarball's binary is already a stable release.
  dontStrip = true;
  dontFixup = stdenvNoCC.hostPlatform.isDarwin;

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenvNoCC.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    install -Dm755 warp-tui-stable "$out/bin/warp"
    mkdir -p "$out/share/warp-agent-cli"
    cp -r resources "$out/share/warp-agent-cli/resources"

    runHook postInstall
  '';

  meta = {
    description = "Standalone terminal-native coding agent CLI from Warp (warp-tui)";
    homepage = "https://www.warp.dev/agent-cli";
    license = lib.licenses.unfree;
    mainProgram = "warp";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

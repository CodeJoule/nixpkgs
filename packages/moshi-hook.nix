{ lib
, stdenvNoCC
, fetchurl
, autoPatchelfHook
}:

let
  version = "0.3.15";

  sources = {
    aarch64-darwin = {
      url = "https://cdn.getmoshi.app/hook/v${version}/moshi-hook_Darwin_arm64.tar.gz";
      hash = "sha256-9FFRrYeaN6WqUWveOLLugaxoWbDGQFa79ICfPfDLVW4=";
    };
    x86_64-darwin = {
      url = "https://cdn.getmoshi.app/hook/v${version}/moshi-hook_Darwin_x86_64.tar.gz";
      hash = "sha256-H+PyKEVQ+fVEKYQZJxwPvLL3nhWK5vHPRYZJvFl34Zk=";
    };
    aarch64-linux = {
      url = "https://cdn.getmoshi.app/hook/v${version}/moshi-hook_Linux_arm64.tar.gz";
      hash = "sha256-V6xlLBh3nNukTbwQRZ1n9xLi7npbeU4j3EgtH9alP2I=";
    };
    x86_64-linux = {
      url = "https://cdn.getmoshi.app/hook/v${version}/moshi-hook_Linux_x86_64.tar.gz";
      hash = "sha256-Eoo2EymzOmvS4Y28OvBkAR4N5+/jDoLiyf+/u6xQ9k8=";
    };
  };

  system = stdenvNoCC.hostPlatform.system;
  source = sources.${system} or (throw "moshi-hook: unsupported system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "moshi-hook";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  # Upstream ships a prebuilt binary — nothing to compile here.
  dontBuild = true;
  dontConfigure = true;
  # Prebuilt release binary; stripping buys nothing and risks breaking it.
  dontStrip = true;

  # The tarball has three top-level entries (README.md, docs/, moshi-hook), so
  # the default unpackPhase's "cd into the single top-level dir" heuristic
  # should not fire — but it has been observed to pick `docs` anyway, which
  # makes installPhase fail to find the binary. Unpack explicitly instead.
  unpackPhase = ''
    runHook preUnpack

    mkdir source
    tar -xzf $src -C source

    runHook postUnpack
  '';
  sourceRoot = "source";

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall

    install -Dm755 moshi-hook "$out/bin/moshi-hook"
    ln -s moshi-hook "$out/bin/moshi"

    runHook postInstall
  '';

  meta = {
    description = "Portable daemon + CLI that bridges AI coding agents to the Moshi mobile app";
    homepage = "https://getmoshi.app";
    license = lib.licenses.unfree;
    mainProgram = "moshi-hook";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}

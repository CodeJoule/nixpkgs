{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, pkg-config
, protobuf
, cmake
, perl
, makeWrapper
, libiconv
, apple-sdk
, openssl
, patchTransparentBg
, patchVesperTheme
, patchVoiceOptSpace
}:

let
  # Pinned open-source tree (xai-org/grok-build). Bump rev + hash together.
  rev = "5da6962e4adb9c857f3def762542b52b4ec3e522";
  version = "0.2.112-transparent+vesper+optspace+${builtins.substring 0 7 rev}";
  src = fetchFromGitHub {
    owner = "xai-org";
    repo = "grok-build";
    inherit rev;
    hash = "sha256-Vy+6kZGs90xFGl7lhtVQflvnLevPgXpzzPCALXzsdFY=";
  };
in
rustPlatform.buildRustPackage {
  pname = "grok";
  inherit version src;

  # transparent_bg → vesper → voice chord (Opt/Alt+Space instead of Ctrl+Space).
  patches = [ patchTransparentBg patchVesperTheme patchVoiceOptSpace ];

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  cargoBuildFlags = [ "-p" "xai-grok-pager-bin" "--bin" "xai-grok-pager" ];
  cargoTestFlags = [ "-p" "xai-grok-pager-bin" ];

  nativeBuildInputs = [
    pkg-config
    protobuf
    cmake
    perl
    makeWrapper
  ];

  buildInputs =
    [ openssl ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      libiconv
      apple-sdk
    ];

  PROTOC = "${protobuf}/bin/protoc";
  PROTOC_INCLUDE = "${protobuf}/include";
  OPENSSL_NO_VENDOR = "1";

  # Full workspace test suite is huge and needs network/fixtures; we only
  # care about a working binary with the personal patches applied.
  doCheck = false;

  postInstall = ''
    # Official installs ship as `grok`; the cargo artifact is xai-grok-pager.
    if [ -e "$out/bin/xai-grok-pager" ]; then
      mv "$out/bin/xai-grok-pager" "$out/bin/grok"
    fi
    wrapProgram "$out/bin/grok" \
      --add-flags --no-auto-update
  '';

  meta = {
    description = "Grok Build (from source) with transparent_bg, Vesper theme, Opt+Space voice";
    homepage = "https://github.com/xai-org/grok-build";
    license = lib.licenses.asl20;
    mainProgram = "grok";
    platforms = lib.platforms.unix;
  };
}

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
}:

let
  # Pinned open-source tree (xai-org/grok-build). Bump rev + hash together.
  rev = "02d9359435d0e9c20a20945679389cdce441e431";
  version = "0.2.112-transparent+vesper+${builtins.substring 0 7 rev}";
  src = fetchFromGitHub {
    owner = "xai-org";
    repo = "grok-build";
    inherit rev;
    hash = "sha256-LBq9PS6jB4+GTcZ+fOEX/QdfYKrSE2bmAVij+vB6ZPk=";
  };
in
rustPlatform.buildRustPackage {
  pname = "grok";
  inherit version src;

  # transparent_bg first (touches Theme::current); vesper second (ThemeKind + palette).
  patches = [ patchTransparentBg patchVesperTheme ];

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
  # care about a working binary with the transparency + Vesper patches.
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
    description = "Grok Build (from source) with transparent_bg, /transparency, and Vesper theme";
    homepage = "https://github.com/xai-org/grok-build";
    license = lib.licenses.asl20;
    mainProgram = "grok";
    platforms = lib.platforms.unix;
  };
}

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
}:

let
  # Pinned open-source tree (xai-org/grok-build). Bump rev + hash together.
  rev = "98c3b2438aa922fbbe6178a5c0a4c48f85edc8ce";
  version = "0.2.102-transparent+${builtins.substring 0 7 rev}";
  src = fetchFromGitHub {
    owner = "xai-org";
    repo = "grok-build";
    inherit rev;
    hash = "sha256-DPnym/wsQ+zIb6kCum070f8/3tOuNjLLA0xDOualNFg=";
  };
in
rustPlatform.buildRustPackage {
  pname = "grok";
  inherit version src;

  patches = [ patchTransparentBg ];

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
  # care about a working binary with the transparency patch.
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
    description = "Grok Build (from source) with transparent_bg theme option";
    homepage = "https://github.com/xai-org/grok-build";
    license = lib.licenses.asl20;
    mainProgram = "grok";
    platforms = lib.platforms.unix;
  };
}

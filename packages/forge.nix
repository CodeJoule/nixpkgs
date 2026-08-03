{ lib
, stdenv
, rustPlatform
, fetchFromGitHub
, cmake
, nasm
, perl
, pkg-config
, protobuf
, sqlite
, libiconv
, apple-sdk
, libxkbcommon
, libx11
, libxext
, libxfixes
, libxcb
, wayland
, patchSupergrok
}:

let
  src = fetchFromGitHub {
    owner = "tailcallhq";
    repo = "forgecode";
    rev = "v2.13.21";
    hash = "sha256-RMiJ9uI76KqzNmXOsgStdPjTz8ZuKtlBTm0xZFJoE34=";
  };
in
rustPlatform.buildRustPackage {
  pname = "forge";
  version = "2.13.21";
  inherit src;

  patches = [ patchSupergrok ];

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  cargoBuildFlags = [ "-p" "forge_main" "--bin" "forge" ];
  cargoInstallFlags = [ "-p" "forge_main" "--bin" "forge" ];

  nativeBuildInputs = [ cmake nasm perl pkg-config protobuf ];

  buildInputs =
    [ sqlite ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      libxkbcommon
      libx11
      libxext
      libxfixes
      libxcb
      wayland
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      libiconv
      apple-sdk
    ];

  PROTOC = "${protobuf}/bin/protoc";
  PROTOC_INCLUDE = "${protobuf}/include";
  APP_VERSION = "2.13.21";

  doCheck = false;

  meta = {
    description = "forge with xAI/SuperGrok OAuth and grok_build (cli-chat-proxy Composer models)";
    homepage = "https://forgecode.dev";
    license = lib.licenses.asl20;
    mainProgram = "forge";
    platforms = lib.platforms.unix;
  };
}
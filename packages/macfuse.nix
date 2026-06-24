{ lib
, stdenvNoCC
, fetchurl
, undmg
, xar
, cpio
, gzip
}:

stdenvNoCC.mkDerivation rec {
  pname = "macfuse";
  version = "5.2.0";

  src = fetchurl {
    url = "https://github.com/macfuse/macfuse/releases/download/macfuse-${version}/macfuse-${version}.dmg";
    sha256 = "09a4b4c23c1930af45335fc119696797da41562dec1630602d2db637f4804f27";
  };

  nativeBuildInputs = [ undmg xar cpio gzip ];

  sourceRoot = ".";

  unpackPhase = ''
    runHook preUnpack
    undmg "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    # Expand the outer installer pkg
    xar -xf "Install macFUSE.pkg"

    # The inner Core pkg contains the actual payload
    cd "Core.pkg"
    cat Payload | gunzip | cpio -id

    mkdir -p "$out/Library/Filesystems"
    mkdir -p "$out/usr/local/lib"
    mkdir -p "$out/usr/local/include"

    cp -R Library/Filesystems/macfuse.fs "$out/Library/Filesystems/"
    cp -R usr/local/lib/. "$out/usr/local/lib/"
    cp -R usr/local/include/. "$out/usr/local/include/"

    runHook postInstall
  '';

  meta = with lib; {
    description = "FUSE for macOS — userspace filesystem framework with FSKit backend";
    homepage = "https://macfuse.io";
    license = licenses.bsd3;
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    maintainers = [ ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}

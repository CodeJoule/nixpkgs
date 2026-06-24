{ lib
, stdenvNoCC
, fetchurl
, xar
, cpio
, gzip
}:

stdenvNoCC.mkDerivation rec {
  pname = "fuse-t";
  version = "1.2.7";

  src = fetchurl {
    url = "https://github.com/macos-fuse-t/fuse-t/releases/download/${version}/fuse-t-macos-installer-${version}.pkg";
    sha256 = "6a29c747e61a86a405a189efc3de42812d73147135f93a1bb0624c1e7b90e654";
  };

  nativeBuildInputs = [ xar cpio gzip ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p work && cd work
    xar -xf "$src"

    mkdir -p payload-core payload-fskit
    cat fuse-t-core.pkg/Payload | gunzip | (cd payload-core && cpio -id)
    cat fuse-t-fskit.pkg/Payload | gunzip | (cd payload-fskit && cpio -id)

    mkdir -p "$out/lib/fuse-t" "$out/Applications"

    cp -R "payload-core/Library/Application Support/fuse-t/." "$out/lib/fuse-t/"
    cp -R "payload-fskit/Applications/fuse-t.app" "$out/Applications/"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Kext-less FUSE for macOS using NFS/FSKit backend";
    homepage = "https://www.fuse-t.org";
    license = licenses.lgpl21Only;
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    maintainers = [ ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}

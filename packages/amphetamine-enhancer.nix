{ lib
, stdenvNoCC
, fetchurl
, undmg
}:

stdenvNoCC.mkDerivation rec {
  pname = "amphetamine-enhancer";
  version = "1.0";

  src = fetchurl {
    url = "https://github.com/x74353/Amphetamine-Enhancer/raw/master/Releases/Current/Amphetamine%20Enhancer.dmg";
    sha256 = "a8848c072e3aae6f89fac99fb4f71bac9cbc96b5b29cc57f7e01235c3e39a14c";
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  unpackPhase = ''
    runHook preUnpack
    undmg "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications"
    cp -R "Amphetamine Enhancer.app" "$out/Applications/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Adds abilities (incl. Power Protect) to the macOS keep-awake app Amphetamine";
    homepage = "https://github.com/x74353/Amphetamine-Enhancer";
    license = licenses.mit;
    platforms = [ "x86_64-darwin" "aarch64-darwin" ];
    maintainers = [ ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
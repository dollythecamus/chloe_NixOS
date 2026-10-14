{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, zlib
}:

stdenv.mkDerivation rec {
  pname = "lightpanda";
  version = "1.0.0";

  src = fetchurl {
    url = "https://github.com/lightpanda-io/browser/releases/download/${version}/lightpanda_${version}_amd64.deb";
    hash = "sha256-cYq1RqsD53dz1CJA0q9Q4kwRaGS0RFzEq3iyCDFGIXs=";
  };

  dontUnpack = true;
  nativeBuildInputs = [ dpkg autoPatchelfHook ];
  buildInputs = [ zlib stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    dpkg-deb --extract "$src" extracted
    install -Dm755 extracted/usr/bin/lightpanda "$out/bin/lightpanda"
    runHook postInstall
  '';

  meta = {
    description = "Headless browser designed for AI and automation";
    homepage = "https://lightpanda.io/";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "lightpanda";
  };
}

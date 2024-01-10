{ lib
, stdenv
, callPackage
, cmake
, doxygen
, git
, pkg-config
, python3
, bzip2
, libzip
, miniupnpc
, openssl
, rapidjson
, sqlcipher
, xapian

, llvmPackages
, Cocoa

, enableWebUI ? true
}:
let
  common = callPackage ./common.nix { };
in
stdenv.mkDerivation rec {
  pname = "retroshare-service";

  inherit (common) version src;

  patches = [
    ./fix-webui-path.patch
    ./fix-clang.patch
  ];

  nativeBuildInputs = [
    cmake
    doxygen
    git
    pkg-config
    python3
  ] ++ lib.optionals stdenv.isDarwin [
    Cocoa
  ];

  buildInputs = [
    bzip2
    libzip
    miniupnpc
    openssl
    rapidjson
    sqlcipher
    xapian
  ];

  preConfigure = ''
    patchShebangs retroshare-webui/webui-src/make-src/build.sh
    cd retroshare-service
  '';

  # Workaround for https://github.com/NixOS/nixpkgs/issues/19098
  env.NIX_CFLAGS_COMPILE = lib.optionalString (stdenv.cc.isClang && stdenv.isDarwin) "-fno-lto";

  cmakeFlags = builtins.map (fl: "-D" + fl) common.RSVersionFlags
  ++ [
    "-DRS_FORUM_DEEP_INDEX=ON"
  ] ++ lib.optionals enableWebUI [
    "-DRS_JSON_API=ON"
    "-DRS_SERVICE_TERMINAL_WEBUI_PASSWORD=ON"
    "-DRS_WEBUI=ON"
  ] ++ lib.optionals stdenv.isDarwin [
    # Fixes https://github.com/RetroShare/libretroshare/issues/122
    "-DRS_FIX_CLANG=ON"

    # A compatible ar/ranlib is equired to build with clang
    "-DCMAKE_CXX_COMPILER_AR=${llvmPackages.libcxxClang}/bin/ar"
    "-DCMAKE_CXX_COMPILER_RANLIB=${llvmPackages.libcxxClang}/bin/ranlib"
  ];

  installPhase = lib.optionalString stdenv.isDarwin ''
    runHook preInstall

    # Temporary workaround so the binary will find the webui without having to specify the path
    # Note: Not a valid bundle/package, but it works for now
    mkdir -p $out/Applications/retroshare.app/Contents/MacOS
    mkdir -p $out/Applications/retroshare.app/Contents/Resources/webui

    cp retroshare-service $out/Applications/retroshare.app/Contents/MacOS/retroshare-service
    cp -r ../../retroshare-webui/webui $out/Applications/retroshare.app/Contents/Resources/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Headless retroshare node";
    homepage = "https://retroshare.cc/";
    license = licenses.agpl3Only;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ StijnDW dandellion];
  };
}

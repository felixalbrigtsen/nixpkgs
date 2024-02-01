{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, pkg-config
, xorg
, libsixel

, AudioUnit
, Cocoa
, CoreServices
, IOKit
, OpenGL
}:

stdenv.mkDerivation {
  pname = "SDL_sixel";
  version = "1.2-nightly";

  src = fetchFromGitHub {
    owner = "saitoha";
    repo = "SDL1.2-SIXEL";
    rev = "ab3fccac6e34260a617be511bd8c2b2beae41952";
    sha256 = "0gm2vngdac17lzw9azkhzazmfq3byjddms14gqjk18vnynfqp5wp";
  };

  patches = [
    # https://github.com/libsdl-org/SDL-1.2/issues/724
    (fetchpatch {
      url = "https://bugzilla-attachments.libsdl.org/attachments/1078/SDL-1.2.15-const_XData32.patch.txt";
      hash = "sha256-OuOpdmkhnJDr/8In2y8uWGewPje+Vx77UHijFlU0XP8=";
    })
  ];

  postPatch = ''
    sed -e 's|Kernel/IOKit/hidsystem/IOHIDUsageTables.h|IOKit/hid/IOHIDUsageTables.h|g' -i ./src/joystick/darwin/SDL_sysjoystick.c
  '';

  configureFlags = [ "--enable-video-sixel" ];

  nativeBuildInputs = [ pkg-config ]
    ++ lib.optionals stdenv.isDarwin [ AudioUnit Cocoa CoreServices IOKit OpenGL ];

  buildInputs = [ libsixel ]
    ++ lib.optionals stdenv.isDarwin [ xorg.libX11 xorg.libXext ];

  meta = with lib; {
    description = "A cross-platform multimedia library, that supports sixel graphics on consoles";
    homepage    = "https://github.com/saitoha/SDL1.2-SIXEL";
    maintainers = with maintainers; [ vrthra ];
    platforms   = platforms.linux ++ platforms.darwin;
    license     = licenses.lgpl21;
  };
}

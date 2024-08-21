{ lib
, stdenv
, fetchFromGitHub
, libbsd
, libevent
, libjpeg
, libdrm
, pkg-config
, janus-gateway
, runCommand
, glib
, alsa-lib
, speex
, jansson
, libopus
, withJanus ? true
}:
let
  patchedJanus = runCommand "janus-gateway-ustreamer-patched" { } ''
    cp -r --no-preserve=mode ${janus-gateway.dev} $out
    substituteInPlace $out/include/janus/plugins/plugin.h --replace 'refcount.h' '../refcount.h'
  '';
in
stdenv.mkDerivation rec {
  pname = "ustreamer";
  version = "6.12";

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "ustreamer";
    rev = "v${version}";
    hash = "sha256-iaCgPHgklk7tbhJhQmyjKggb1bMWBD+Zurgfk9sCQ3E=";
  };

  buildInputs = [
    libbsd
    libevent
    libjpeg
    libdrm
  ] ++ lib.optionals withJanus [
    patchedJanus
    glib
    alsa-lib
    jansson
    speex
    libopus
  ];

  nativeBuildInputs = [ pkg-config ];

  makeFlags = [
    "PREFIX=${placeholder "out"}"
    "WITH_V4P=1"
  ] ++ lib.optionals withJanus [
    "WITH_JANUS=1"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://github.com/pikvm/ustreamer";
    description = "Lightweight and fast MJPG-HTTP streamer";
    longDescription = ''
      µStreamer is a lightweight and very quick server to stream MJPG video from
      any V4L2 device to the net. All new browsers have native support of this
      video format, as well as most video players such as mplayer, VLC etc.
      µStreamer is a part of the Pi-KVM project designed to stream VGA and HDMI
      screencast hardware data with the highest resolution and FPS possible.
    '';
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ tfc matthewcroughan ];
    platforms = platforms.linux;
  };
}


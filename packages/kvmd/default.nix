{ lib
, python3
, fetchFromGitHub
, libxkbcommon
, ustreamer
, tesseract
, makeWrapper

# undeclared runtime deps
, libraspberrypi
, coreutils
, sudo
, iproute2
, iptables
, systemdMinimal
, janus-gateway
, mount
, stdenv
}:
let
  ustreamer-python = python3.pkgs.buildPythonPackage {
    pname = "ustreamer";
    version = ustreamer.version;
    src = ustreamer.src;
    prePatch = ''
      cd python
    '';
  };
in
python3.pkgs.buildPythonApplication rec {
  pname = "kvmd";
  version = "4.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "kvmd";
    rev = "v${version}";
    hash = "sha256-c/E9ce9cy0AScEVb8KsTZ7zmk8rpsiW0RnkgrOLYufw=";
  };

  nativeBuildInputs = [
    python3.pkgs.setuptools
    python3.pkgs.wheel
    makeWrapper
  ];

  propagatedBuildInputs = with python3.pkgs; [
    ustreamer-python
    pyyaml
    aiohttp
    aiofiles
    async-lru
    passlib
    pyotp
    qrcode
    python-periphery
    pyserial
    pyserial-asyncio
    spidev
    setproctitle
    psutil
    netifaces
    systemd
    dbus-python
    dbus-next
    pygments
    (callPackage ./pyghmi.nix {})
    pam
    pillow
    xlib
    zstandard
    libgpiod
    mako
  ];

  pythonImportsCheck = [
    "kvmd"
    "kvmd"
    "kvmd.validators"
    "kvmd.yamlconf"
    "kvmd.keyboard"
    "kvmd.plugins"
    "kvmd.plugins.auth"
    "kvmd.plugins.hid"
    "kvmd.plugins.hid._mcu"
    "kvmd.plugins.hid.otg"
    "kvmd.plugins.hid.bt"
    "kvmd.plugins.hid.ch9329"
    "kvmd.plugins.atx"
    "kvmd.plugins.msd"
    "kvmd.plugins.msd.otg"
    "kvmd.plugins.ugpio"
    "kvmd.clients"
    "kvmd.apps"
    "kvmd.apps.kvmd"
    "kvmd.apps.kvmd.info"
    "kvmd.apps.kvmd.api"
    "kvmd.apps.pst"
    "kvmd.apps.pstrun"
    "kvmd.apps.otg"
    "kvmd.apps.otg.hid"
    "kvmd.apps.otgnet"
    "kvmd.apps.otgmsd"
    "kvmd.apps.otgconf"
    "kvmd.apps.htpasswd"
    "kvmd.apps.totp"
    "kvmd.apps.edidconf"
    "kvmd.apps.cleanup"
    "kvmd.apps.ipmi"
    "kvmd.apps.vnc"
    "kvmd.apps.vnc.rfb"
    "kvmd.apps.ngxmkconf"
    "kvmd.apps.janus"
    "kvmd.apps.watchdog"
    "kvmd.helpers"
    "kvmd.helpers.remount"
    "kvmd.helpers.swapfiles"
  ];

  buildInputs = [
    libxkbcommon
  ];

  patchPhase = ''
    runHook prePatch
    pwd
    ls -lah

    substituteInPlace kvmd/libc.py --replace-fail 'ctypes.util.find_library("c")' '"${stdenv.cc.libc}/lib/libc.so.6"'
    substituteInPlace kvmd/keyboard/printer.py --replace-fail 'ctypes.util.find_library("xkbcommon")' '"${libxkbcommon}/lib/libxkbcommon.so"'
    substituteInPlace kvmd/apps/kvmd/ocr.py --replace-fail 'ctypes.util.find_library("tesseract")' '"${tesseract}/lib/libtesseract.so"'

    cd configs/os/services

    rm kvmd-certbot*
    rm kvmd-nginx*
    rm kvmd-janus-static*

    for i in $(find -name '*.service')
    do
      substituteInPlace $i \
        --replace '/usr/bin/kvmd' "$out/bin/kvmd" \
        --replace '/usr/bin/ustreamer' '${ustreamer}/bin/ustreamer'
    done
    cd -
    
    for i in $(find -name '*.py')
    do
      substituteInPlace $i \
        --replace '/usr/share/kvmd' "$out/share" \
        --replace '/usr/bin/kvmd-' "$out/bin/kvmd-" \
        --replace '/usr/bin/vcgencmd' "${libraspberrypi}/bin/vcgencmd" \
        --replace '/bin/true' "${coreutils}/bin/true" \
        --replace '/usr/bin/sudo' "/run/wrappers/bin/sudo" \
        --replace '/usr/bin/kvmd-helper-pst-remount' "$out/bin/kvmd-helper-pst-remount" \
        --replace '/usr/bin/ip' "${iproute2}/bin/ip" \
        --replace '/usr/sbin/iptables' "${iptables}/bin/iptables" \
        --replace '/usr/bin/systemd-run' "${systemdMinimal}/bin/systemd-run" \
        --replace '/usr/bin/systemctl' "${systemdMinimal}/bin/systemctl" \
        --replace '/etc/kvmd/ipmipasswd' '${builtins.toFile "dummy.txt" ""}' \
        --replace '/etc/kvmd/vnc/ssl/server.crt' '${builtins.toFile "dummy.txt" ""}' \
        --replace '/etc/kvmd/vnc/ssl/server.key' '${builtins.toFile "dummy.txt" ""}' \
        --replace '/etc/kvmd/vncpasswd' '${builtins.toFile "dummy.txt" ""}' \
        --replace '/usr/bin/janus' '${janus-gateway}/bin/janus' \
        --replace '/bin/mount' '/run/wrappers/bin/mount' \
        --replace '/usr/share/tessdata' '${tesseract}/share' \
        --replace '/usr/lib/ustreamer/janus' '${ustreamer}/lib/ustreamer/janus'
    done

#    exit 1
     
    runHook postPatch
  '';

  postFixup = ''
    mkdir -p $out/share $out/lib/systemd/system
    cp ${janus-gateway.doc}/share/janus/javascript/janus.js web/share/js/kvm/janus.js
    cp -r {hid,web,extras,contrib/keymaps,configs/*} $out/share
    cp configs/os/services/*.service $out/lib/systemd/system
  '';

  meta = with lib; {
    description = "The main PiKVM daemon";
    homepage = "https://github.com/pikvm/kvmd/blob/master/PKGBUILD";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ matthewcroughan ];
    mainProgram = "kvmd";
  };
}

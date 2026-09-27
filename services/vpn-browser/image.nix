{ pkgs, lib }:

# Nix-built OCI image for the containerized LibreWolf. Nothing is pulled from
# a registry: it uses the flake-pinned librewolf with the container-only
# settings baked in. The tag is the Nix output hash, so every rebuild that
# changes the contents produces a new tag and the launcher reloads it.
#
# GPU userspace is NOT bundled: the launcher bind-mounts the host's
# /run/opengl-driver and its store closure (mesa, NVIDIA, egl-wayland)
# read-only at runtime, so it always matches the running kernel driver.
let
  settings = import ./librewolf-settings.nix { inherit lib; };

  librewolf = pkgs.librewolf.override {
    inherit (settings) extraPrefs extraPolicies;
  };

  fontsConf = pkgs.makeFontsConf {
    fontDirectories = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      dejavu_fonts
    ];
  };

  # fonts.conf includes /etc/fonts/conf.d; without it the generic families
  # (sans-serif/serif/monospace) have no aliases and everything falls back to
  # an arbitrary font. Ship fontconfig's stock rules + our preferred defaults.
  fontsEtc = pkgs.runCommand "vpn-browser-fontconfig-etc" { } ''
    mkdir -p $out/etc/fonts/conf.d
    ln -s ${pkgs.fontconfig.out}/etc/fonts/conf.d/*.conf $out/etc/fonts/conf.d/
    cat > $out/etc/fonts/conf.d/52-vpn-browser-defaults.conf <<'EOF'
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <alias binding="same"><family>sans-serif</family>
        <prefer><family>Noto Sans</family><family>Noto Sans CJK SC</family><family>Noto Color Emoji</family></prefer>
      </alias>
      <alias binding="same"><family>serif</family>
        <prefer><family>Noto Serif</family><family>Noto Sans CJK SC</family><family>Noto Color Emoji</family></prefer>
      </alias>
      <alias binding="same"><family>monospace</family>
        <prefer><family>DejaVu Sans Mono</family><family>Noto Sans Mono</family><family>Noto Color Emoji</family></prefer>
      </alias>
      <alias binding="same"><family>emoji</family>
        <prefer><family>Noto Color Emoji</family></prefer>
      </alias>
    </fontconfig>
    EOF
  '';
in
pkgs.dockerTools.streamLayeredImage {
  name = "localhost/vpn-browser-librewolf";

  contents = with pkgs; [
    librewolf
    bashInteractive
    coreutils
    cacert
    fontconfig
    fontsEtc
    adwaita-icon-theme
    hicolor-icon-theme
    shared-mime-info
  ];

  fakeRootCommands = ''
    mkdir -p tmp etc
    chmod 1777 tmp
    echo "5670a1d5e0b7c0ffee0dface00000001" > etc/machine-id
    cat > etc/nsswitch.conf <<'EOF'
    passwd:    files
    group:     files
    hosts:     files dns
    EOF

    # nixpkgs NSS loads p11-kit-trust as its root store, which reads
    # /etc/ssl/certs/ca-certificates.crt (as on NixOS). Without it every
    # HTTPS site fails with SEC_ERROR_UNKNOWN_ISSUER.
    mkdir -p etc/ssl/certs
    ln -sf ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt etc/ssl/certs/ca-certificates.crt
  '';

  config = {
    Entrypoint = [ "${librewolf}/bin/librewolf" ];
    Env = [
      "PATH=/bin"
      "LANG=C.UTF-8"
      "MOZ_ENABLE_WAYLAND=1"
      "GDK_BACKEND=wayland"
      "FONTCONFIG_FILE=${fontsConf}"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "XDG_DATA_DIRS=/share"
      # No session bus in the container; silence the a11y bridge warning.
      "NO_AT_BRIDGE=1"
    ];
  };
}

{
  inputs,
  pkgs,
  username,
  ...
}:

let
  # Agenix decrypts during activation, which would normally make the entire
  # switch fail when a new host is not a recipient yet. Preserve normal
  # decryption when possible, but install an empty placeholder when it fails.
  # Consumers keep their stable age.secrets.<name>.path and fail only when the
  # unavailable credential is actually used. New secrets inherit this behavior
  # automatically without per-secret or per-consumer conditions.
  ageWithPlaceholderFallback = pkgs.writeShellScript "age-with-placeholder-fallback" ''
    output=""
    expect_output=false

    for arg in "$@"; do
      if $expect_output; then
        output="$arg"
        expect_output=false
        continue
      fi

      case "$arg" in
        -o|--output)
          expect_output=true
          ;;
        --output=*)
          output="''${arg#--output=}"
          ;;
      esac
    done

    if ${pkgs.age}/bin/age "$@"; then
      exit 0
    fi

    if [ -z "$output" ]; then
      echo "[agenix] ERROR: decryption failed and no output path was provided" >&2
      exit 1
    fi

    echo "[agenix] WARNING: decryption failed; installing an empty placeholder at $output" >&2
    rm -f -- "$output"
    : > "$output"
  '';
in
{
  environment.systemPackages = [ inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  age.ageBin = "${ageWithPlaceholderFallback}";

  # Decrypted at activation (tmpfs, never in store/git). Owned by the user so
  # opencode (home-manager) can read it. The consumer references the resolved
  # path via osConfig.age.secrets.deepseek-api.path (see modules/ai/_opencode.nix),
  # so this stays platform-agnostic.
  #
  # NOTE: the agenix MODULE is imported per-platform in hosts/default.nix
  # (agenix.nixosModules.default for NixOS/WSL; agenix.darwinModules.default
  # for a future macOS host). This declaration itself is shared.
  age.secrets.deepseek-api = {
    file = ../../secrets/deepseek-api.age;
    owner = username;
    mode = "0400";
  };

  age.secrets.opencode-api = {
    file = ../../secrets/opencode-api.age;
    owner = username;
    mode = "0400";
  };

  # Git SSH auth keys. Consumed by Home Manager's programs.ssh (see
  # modules/development/_git-config.nix) via osConfig.age.secrets.<name>.path.
  # Mode 0600 is required: ssh refuses to use a private key with looser perms.
  age.secrets.gitlab-main = {
    file = ../../secrets/gitlab-main.age;
    owner = username;
    mode = "0600";
  };

  age.secrets.gitlab-burner = {
    file = ../../secrets/gitlab-burner.age;
    owner = username;
    mode = "0600";
  };

  age.secrets.github-main = {
    file = ../../secrets/github-main.age;
    owner = username;
    mode = "0600";
  };

  age.secrets.github-burner = {
    file = ../../secrets/github-burner.age;
    owner = username;
    mode = "0600";
  };

  age.secrets.nerv-centr = {
    file = ../../secrets/nerv-centr.age;
    owner = username;
    mode = "0600";
  };
}

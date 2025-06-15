_: let
  excludes = [];
in {
  # General
  check-case-conflicts = {
    enable = true;
    inherit excludes;
    types = ["text"];
  };
  detect-private-keys = {
    enable = true;
    inherit excludes;
    types = ["text"];
  };
  end-of-file-fixer = {
    enable = true;
    inherit excludes;
    types = ["text"];
  };
  fix-byte-order-marker = {
    enable = true;
    inherit excludes;
  };
  mixed-line-endings = {
    enable = true;
    inherit excludes;
    types = ["text"];
  };
  trim-trailing-whitespace = {
    enable = true;
    inherit excludes;
    types = ["text"];
  };
  typos = {
    args = ["--force-exclude"];
    enable = true;
    inherit excludes;
    settings.configPath = "typos.toml";
  };

  # Nix
  alejandra.enable = true;
  deadnix.enable = true;
  statix.enable = true;

  # Rust
  rustfmt = {
    enable = true;
  };
  taplo = {
    enable = true;
    inherit excludes;
    types = ["toml"];
  };

  # Shell
  shellcheck = {
    enable = true;
    excludes = [".envrc"] ++ excludes;
  };
  shfmt = {
    args = ["--indent" "4" "--space-redirects"];
    enable = true;
    inherit excludes;
  };
}

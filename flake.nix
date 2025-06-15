{
  description = "A tui-based PDF viewer";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    git-hooks,
    nixpkgs,
    crane,
    rust-overlay,
    self,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        git-hooks.flakeModule
      ];

      perSystem = {
        config,
        lib,
        pkgs,
        system,
        ...
      }: let
        rust = pkgs.rust-bin.nightly.latest.default;
        craneLib = (crane.mkLib pkgs).overrideToolchain rust;

        nativeBuildInputs = with pkgs; [
          clang
          pkg-config
          rust
        ];

        buildInputs = with pkgs; [
          fontconfig
        ];

        LIBCLANG_PATH = lib.makeLibraryPath [pkgs.llvmPackages_latest.libclang.lib];
      in {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [rust-overlay.overlays.default];
        };

        # Option from the git-hooks flake module.
        pre-commit.settings.hooks = import ./pre-commit-hooks.nix {inherit pkgs;};

        devShells.default = pkgs.mkShell {
          inherit buildInputs nativeBuildInputs LIBCLANG_PATH;

          shellHook = ''
            # Generate .pre-commit-config.yaml symlink.
            ${config.pre-commit.installationScript}
          '';
        };

        packages.default = let
          commonArgs = {
            src = craneLib.cleanCargoSource ./.;
            strictDeps = true;
            inherit buildInputs nativeBuildInputs LIBCLANG_PATH;
          };
        in
          craneLib.buildPackage (commonArgs
            // {
              cargoArtifacts = craneLib.buildDepsOnly commonArgs;

              meta = with lib; {
                description = "A tui-based PDF viewer";
                homepage = "https://github.com/itsjunetime/tdf";
                license = licenses.agpl3Only;
                mainProgram = "tdf";
                platforms = platforms.unix;
              };
            });

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/tdf";
        };
      };
    };
}

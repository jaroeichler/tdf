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
        rust = pkgs.rust-bin.selectLatestNightlyWith (
          toolchain:
            toolchain.default.override {
              extensions = ["rust-src"];
              targets = ["x86_64-unknown-linux-musl"];
            }
        );

        nativeBuildInputs = with pkgs; [
          clang
        ];
        buildInputs = with pkgs; [];

        LIBCLANG_PATH = lib.makeLibraryPath [pkgs.clang.cc.lib];
      in {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [rust-overlay.overlays.default];
        };

        # Option from the git-hooks flake module.
        pre-commit.settings.hooks = import ./pre-commit-hooks.nix {inherit pkgs;};

        devShells.default = pkgs.mkShell {
          inherit buildInputs nativeBuildInputs LIBCLANG_PATH;

          packages = with pkgs; [
            rust
          ];

          shellHook = ''
            # Generate .pre-commit-config.yaml symlink.
            ${config.pre-commit.installationScript}
          '';
        };

        packages.default = let
          commonArgs = {
            inherit buildInputs nativeBuildInputs LIBCLANG_PATH;

            hardeningDisable = ["fortify"];
            src = craneLib.cleanCargoSource ./.;
            stdenv = p: p.pkgsMusl.stdenv;
            strictDeps = true;

            CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl";
            CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
            CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER = "${pkgs.mold}/bin/ld.mold";
          };

          craneLib = (crane.mkLib pkgs).overrideToolchain rust;
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

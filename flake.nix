{
  description = "Nix flake exposing imds-broker and sandy packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    imds-broker-src = {
      url = "github:jamestelfer/imds-broker/v0.3.0";
      flake = false;
    };

    sandy-src = {
      url = "github:jamestelfer/sandy/v0.5.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, imds-broker-src, sandy-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          imds-broker = pkgs.buildGoModule {
            pname = "imds-broker";
            version = "0.3.0";

            src = imds-broker-src;

            vendorHash = "sha256-goNU950kwkBVSNSq9NCZbBvd/iRArCypYvRleS+wMyY=";

            subPackages = [ "cmd/imds-broker" ];

            meta = {
              description = "Vends AWS credentials via IMDSv2 for Docker containers, local dev tools, and AI agents";
              homepage = "https://github.com/jamestelfer/imds-broker";
              license = pkgs.lib.licenses.mit;
              mainProgram = "imds-broker";
            };
          };

          sandy = pkgs.stdenv.mkDerivation {
            pname = "sandy";
            version = "0.5.0";

            src = sandy-src;

            nativeBuildInputs = with pkgs; [
              bun
              nodejs
            ];

            buildPhase = ''
              runHook preBuild

              export HOME=$TMPDIR

              bun install --frozen-lockfile
              bun scripts/pack-embedded.ts
              bun build --compile --target=bun src/main.ts --outfile dist/sandy

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              cp dist/sandy $out/bin/sandy

              runHook postInstall
            '';

            meta = {
              description = "Sandboxed TypeScript runtime for AI coding agents to query AWS";
              homepage = "https://github.com/jamestelfer/sandy";
              license = pkgs.lib.licenses.mit;
              mainProgram = "sandy";
            };
          };
        };
      });
}

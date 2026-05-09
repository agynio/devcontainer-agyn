ARG BASE_IMAGE=ghcr.io/agynio/devcontainer:sha-8ff09f8
FROM ${BASE_IMAGE}

# NIXPKGS_ALLOW_UNFREE is required for terraform (BSL since 1.6).
RUN NIXPKGS_ALLOW_UNFREE=1 nix-env --impure -iA \
        nixpkgs.nodejs_24 \
        nixpkgs.go \
        nixpkgs.terraform \
        nixpkgs.gh \
    && nix-store --gc \
    && nix-store --optimise

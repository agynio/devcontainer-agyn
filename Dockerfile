ARG BASE_IMAGE=ghcr.io/agynio/devcontainer:sha-8ff09f8
FROM ${BASE_IMAGE}

# NIXPKGS_ALLOW_UNFREE is required for terraform (BSL since 1.6).
RUN NIXPKGS_ALLOW_UNFREE=1 nix-env --impure -f '<nixpkgs>' -iA \
        nodejs_24 \
        go \
        terraform \
        ripgrep \
        git \
        gh \
    && GH_PROMPT_DISABLED=1 gh extension install agynio/gh-pr-review \
    && nix-store --gc \
    && nix-store --optimise

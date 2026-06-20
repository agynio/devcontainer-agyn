ARG BASE_IMAGE=ghcr.io/agynio/devcontainer:sha-8ff09f8
FROM ${BASE_IMAGE}

ARG TARGETARCH
ARG TERRAFORM_VERSION=1.15.2
ARG TFX_CLI_VERSION=0.23.3

RUN mkdir -p /etc/nix \
    && printf '%s\n' \
        'sandbox = false' \
        'filter-syscalls = false' \
        > /etc/nix/nix.conf \
    && nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs \
    && nix-channel --update \
    && nix-env --impure -f '<nixpkgs>' -iA \
        nodejs_24 \
        go \
        ripgrep \
        git \
        gh \
        curl \
        unzip \
    && case "${TARGETARCH}" in \
        amd64) terraform_arch=amd64 ;; \
        arm64) terraform_arch=arm64 ;; \
        '') terraform_arch="$(uname -m)"; \
            case "${terraform_arch}" in \
                x86_64) terraform_arch=amd64 ;; \
                aarch64) terraform_arch=arm64 ;; \
                *) echo "Unsupported host architecture: ${terraform_arch}" >&2; exit 1 ;; \
            esac ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl --retry 5 --retry-all-errors -fsSLo /tmp/terraform.zip \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${terraform_arch}.zip" \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm /tmp/terraform.zip \
    && npm config set prefix /usr/local \
    && npm install -g "tfx-cli@${TFX_CLI_VERSION}" \
    && GH_PROMPT_DISABLED=1 gh extension install agynio/gh-pr-review \
    && nix-store --gc

ARG BASE_IMAGE=ghcr.io/agynio/devcontainer:sha-8ff09f8
FROM ${BASE_IMAGE}

ARG TARGETARCH
ARG TERRAFORM_VERSION=1.15.2
ARG TFX_CLI_VERSION=0.23.3
ARG GH_PR_REVIEW_VERSION=v1.6.2

RUN case "${TARGETARCH}" in \
        amd64) image_arch=amd64 ;; \
        arm64) image_arch=arm64 ;; \
        '') image_arch="$(uname -m)"; \
            case "${image_arch}" in \
                x86_64) image_arch=amd64 ;; \
                aarch64) image_arch=arm64 ;; \
                *) echo "Unsupported host architecture: ${image_arch}" >&2; exit 1 ;; \
            esac ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && mkdir -p /etc/nix \
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
    && curl --retry 5 --retry-all-errors -fsSLo /tmp/terraform.zip \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${image_arch}.zip" \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm /tmp/terraform.zip \
    && npm config set prefix /usr/local \
    && npm install -g "tfx-cli@${TFX_CLI_VERSION}" \
    && gh_extension_dir="${HOME}/.local/share/gh/extensions/gh-pr-review" \
    && gh_extension_path="${gh_extension_dir}/gh-pr-review" \
    && mkdir -p "${gh_extension_dir}" \
    && curl --retry 5 --retry-all-errors -fsSLo "${gh_extension_path}" \
        "https://github.com/agynio/gh-pr-review/releases/download/${GH_PR_REVIEW_VERSION}/linux-${image_arch}" \
    && chmod +x "${gh_extension_path}" \
    && printf '%s\n' \
        'owner: agynio' \
        'name: gh-pr-review' \
        'host: github.com' \
        "tag: ${GH_PR_REVIEW_VERSION}" \
        'ispinned: true' \
        "path: ${gh_extension_path}" \
        > "${gh_extension_dir}/manifest.yml" \
    && nix-store --gc

ARG BASE_IMAGE=ghcr.io/agynio/devcontainer:sha-8ff09f8
FROM ${BASE_IMAGE}

ARG TARGETARCH
ARG TERRAFORM_VERSION=1.15.2
ARG TFX_CLI_VERSION=0.23.3
ARG GH_PR_REVIEW_VERSION=v1.6.2
ARG GH_PR_REVIEW_LINUX_AMD64_SHA256=2b7d4f2416f195e98010cb3e2b5684b285808e62864f89dea8497dbe691d7ed0
ARG GH_PR_REVIEW_LINUX_ARM64_SHA256=fea079f78e7224200d23de847b6210134ccec1a4d2dcff96ca8ca4ce1060fdde

RUN case "${TARGETARCH}" in \
        amd64) image_arch=amd64; gh_pr_review_sha256="${GH_PR_REVIEW_LINUX_AMD64_SHA256}" ;; \
        arm64) image_arch=arm64; gh_pr_review_sha256="${GH_PR_REVIEW_LINUX_ARM64_SHA256}" ;; \
        '') image_arch="$(uname -m)"; \
            case "${image_arch}" in \
                x86_64) image_arch=amd64; gh_pr_review_sha256="${GH_PR_REVIEW_LINUX_AMD64_SHA256}" ;; \
                aarch64) image_arch=arm64; gh_pr_review_sha256="${GH_PR_REVIEW_LINUX_ARM64_SHA256}" ;; \
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
    && gh_pr_review_path="${HOME}/.local/share/gh/extensions/gh-pr-review/gh-pr-review" \
    && GH_NO_UPDATE_NOTIFIER=1 gh extension install agynio/gh-pr-review --pin "${GH_PR_REVIEW_VERSION}" \
    && printf '%s  %s\n' "${gh_pr_review_sha256}" "${gh_pr_review_path}" | sha256sum -c - \
    && nix-store --gc

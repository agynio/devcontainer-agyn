ARG BASE_IMAGE=ghcr.io/agynio/devcontainer:sha-8ff09f8
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        fontconfig \
        fonts-dejavu-core \
        fonts-liberation \
        fonts-noto-core \
        fonts-noto-cjk \
        fonts-noto-color-emoji; \
    fc-cache -f; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ARG TARGETARCH
ARG TERRAFORM_VERSION=1.15.2
ARG TFX_CLI_VERSION=0.23.3
ARG GH_PR_REVIEW_VERSION=v1.6.2
ARG GH_PR_REVIEW_LINUX_AMD64_SHA256
ARG GH_PR_REVIEW_LINUX_ARM64_SHA256
ARG OUTLINE_CLI_VERSION=v0.3.0
ARG OUTLINE_CLI_LINUX_AMD64_SHA256
ARG OUTLINE_CLI_LINUX_ARM64_SHA256

RUN case "${TARGETARCH}" in \
        amd64) image_arch=amd64; gh_pr_review_sha256_override="${GH_PR_REVIEW_LINUX_AMD64_SHA256}"; outline_cli_sha256_override="${OUTLINE_CLI_LINUX_AMD64_SHA256}" ;; \
        arm64) image_arch=arm64; gh_pr_review_sha256_override="${GH_PR_REVIEW_LINUX_ARM64_SHA256}"; outline_cli_sha256_override="${OUTLINE_CLI_LINUX_ARM64_SHA256}" ;; \
        '') image_arch="$(uname -m)"; \
            case "${image_arch}" in \
                x86_64) image_arch=amd64; gh_pr_review_sha256_override="${GH_PR_REVIEW_LINUX_AMD64_SHA256}"; outline_cli_sha256_override="${OUTLINE_CLI_LINUX_AMD64_SHA256}" ;; \
                aarch64) image_arch=arm64; gh_pr_review_sha256_override="${GH_PR_REVIEW_LINUX_ARM64_SHA256}"; outline_cli_sha256_override="${OUTLINE_CLI_LINUX_ARM64_SHA256}" ;; \
                *) echo "Unsupported host architecture: ${image_arch}" >&2; exit 1 ;; \
            esac ;; \
        *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && if [ -n "${gh_pr_review_sha256_override}" ]; then \
        gh_pr_review_sha256="${gh_pr_review_sha256_override}"; \
    else \
        case "${GH_PR_REVIEW_VERSION}:${image_arch}" in \
            v1.6.2:amd64) gh_pr_review_sha256=2b7d4f2416f195e98010cb3e2b5684b285808e62864f89dea8497dbe691d7ed0 ;; \
            v1.6.2:arm64) gh_pr_review_sha256=fea079f78e7224200d23de847b6210134ccec1a4d2dcff96ca8ca4ce1060fdde ;; \
            v1.6.1:amd64) gh_pr_review_sha256=b4df605705ae0cfc169de9fdd313660dd042b966faee6254ebb7518e3232f37e ;; \
            v1.6.1:arm64) gh_pr_review_sha256=37b7ac75693512d52d96b31f8d2938fdb75428a864d73c1169d23df1d52ab984 ;; \
            *) echo "Unsupported gh-pr-review release: ${GH_PR_REVIEW_VERSION}/${image_arch}" >&2; exit 1 ;; \
        esac; \
    fi \
    && if [ -n "${outline_cli_sha256_override}" ]; then \
        outline_cli_sha256="${outline_cli_sha256_override}"; \
    else \
        case "${OUTLINE_CLI_VERSION}:${image_arch}" in \
            v0.3.0:amd64) outline_cli_sha256=e17a55ae4f3600dc0f7af7aac92d5a6af23e01f4a8499ab8666f86947fb711cb ;; \
            v0.3.0:arm64) outline_cli_sha256=f1d9e78292113aa3759c6e4403617bfa251014d9a358322840dc1add2b986feb ;; \
            *) echo "Unsupported outline-cli release: ${OUTLINE_CLI_VERSION}/${image_arch}" >&2; exit 1 ;; \
        esac; \
    fi \
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
    && curl --retry 5 --retry-all-errors -fsSLo /tmp/outline.tar.gz \
        "https://github.com/agynio/outline-cli/releases/download/${OUTLINE_CLI_VERSION}/outline_${OUTLINE_CLI_VERSION}_linux_${image_arch}.tar.gz" \
    && printf '%s  %s\n' "${outline_cli_sha256}" /tmp/outline.tar.gz | sha256sum -c - \
    && tar -xzf /tmp/outline.tar.gz -C /usr/local/bin outline \
    && chmod +x /usr/local/bin/outline \
    && rm /tmp/outline.tar.gz \
    && npm config set prefix /usr/local \
    && npm install -g "tfx-cli@${TFX_CLI_VERSION}" \
    && gh_pr_review_path="/opt/gh-pr-review/gh-pr-review" \
    && mkdir -p "$(dirname "${gh_pr_review_path}")" \
    && curl --retry 5 --retry-all-errors -fsSLo "${gh_pr_review_path}" \
        "https://github.com/agynio/gh-pr-review/releases/download/${GH_PR_REVIEW_VERSION}/linux-${image_arch}" \
    && printf '%s  %s\n' "${gh_pr_review_sha256}" "${gh_pr_review_path}" | sha256sum -c - \
    && chmod +x "${gh_pr_review_path}" \
    && cd "$(dirname "${gh_pr_review_path}")" \
    && gh extension install . \
    && nix-store --gc

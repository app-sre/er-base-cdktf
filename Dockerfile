
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.4 AS prod
COPY --from=ghcr.io/astral-sh/uv:0.4.29@sha256:ebb10c5178c7a357d80527f3371e7038561c26234e8a0bb323ea1f2ce8a694b7 /uv /bin/uv

LABEL konflux.additional-tags="0.2.0"

USER 0

# Standard path variables
ENV HOME="/home/app" \
    APP="/home/app/src"

# CDKTF and Terraform versions and other related variables
ENV TF_VERSION="1.6.6" \
    CDKTF_VERSION="0.20.8" \
    NODEJS_VERSION="20" \
    JSII_RUNTIME_PACKAGE_CACHE_ROOT=/tmp/jssi-runtime-cache

# Python and UV related variables
ENV \
    # compile bytecode for faster startup
    UV_COMPILE_BYTECODE="true" \
    # disable uv cache. it doesn't make sense in a container
    UV_NO_CACHE=true \
    # uv will run without updating the uv.lock file.
    UV_FROZEN=true \
    # Activate the virtual environment
    PATH="${APP}/.venv/bin:${PATH}"

COPY LICENSE /licenses/LICENSE

# Install python
RUN microdnf install -y python3.11 && \
    update-alternatives --install /usr/bin/python3 python /usr/bin/python3.11 1

# Install nodejs and other dependencies
RUN INSTALL_PKGS="make nodejs nodejs-nodemon nodejs-full-i18n npm findutils tar which unzip" && \
    microdnf -y module disable nodejs && \
    microdnf -y module enable nodejs:$NODEJS_VERSION && \
    microdnf -y --nodocs --setopt=install_weak_deps=0 install $INSTALL_PKGS && \
    microdnf clean all && \
    rm -rf /mnt/rootfs/var/cache/* /mnt/rootfs/var/log/dnf* /mnt/rootfs/var/log/yum.*

# Install CDKTF
RUN node -v | grep -qe "^v$NODEJS_VERSION\." && echo "Found VERSION $NODEJS_VERSION" && \
    npm install --global cdktf-cli@${CDKTF_VERSION} && \
    rm -rf ${HOME}/.npm

# Install Terraform
RUN curl -sfL https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip \
    -o terraform.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/terraform && \
    rm terraform.zip

# Clean up /tmp
RUN rm -rf /tmp && mkdir /tmp && chmod 1777 /tmp

# User setup
RUN useradd -u 1001 -g 0 -d ${HOME} -M -s /sbin/nologin -c "Default Application User" app && \
    chown -R 1001:0 ${HOME}
USER app

WORKDIR ${APP}

COPY .terraformrc ${HOME}/

# Create default virtual environment and install dependencies
COPY requirements.txt ./
RUN uv venv --python /usr/bin/python3.11 && uv pip install -r requirements.txt

FROM prod AS test
COPY Makefile ./
RUN make test

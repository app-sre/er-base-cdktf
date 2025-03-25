
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.5-1742914212@sha256:ac61c96b93894b9169221e87718733354dd3765dd4a62b275893c7ff0d876869 AS prod

LABEL konflux.additional-tags="cdktf-0.20.11-tf-1.6.6-py-3.12-v0.6.0"

USER 0

# Standard path variables
ENV HOME="/home/app" \
    APP="/home/app/src"

# CDKTF and Terraform versions and other related variables
ENV TF_VERSION="1.6.6" \
    CDKTF_VERSION="0.20.11" \
    NODEJS_VERSION="20" \
    JSII_RUNTIME_PACKAGE_CACHE_ROOT=/tmp/jsii-runtime-cache \
    DISABLE_VERSION_CHECK=1 \
    CDKTF_DISABLE_PLUGIN_CACHE_ENV=1 \
    TF_PLUGIN_CACHE_DIR=/.terraform.d/plugin-cache/ \
    TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=true

COPY LICENSE /licenses/LICENSE

# Install python
RUN microdnf install -y python3.12 && \
    update-alternatives --install /usr/bin/python3 python /usr/bin/python3.12 1 && \
    microdnf clean all && \
    rm -rf /mnt/rootfs/var/cache/* /mnt/rootfs/var/log/dnf* /mnt/rootfs/var/log/yum.*

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

RUN mkdir -p ${TF_PLUGIN_CACHE_DIR} && chown 1001:0 ${TF_PLUGIN_CACHE_DIR}

# Clean up /tmp
RUN rm -rf /tmp && mkdir /tmp && chmod 1777 /tmp

COPY cdktf-provider-sync /usr/local/bin/cdktf-provider-sync

# User setup
RUN useradd -u 1001 -g 0 -d ${HOME} -M -s /sbin/nologin -c "Default Application User" app && \
    chown -R 1001:0 ${HOME}
USER app

WORKDIR ${APP}
COPY entrypoint.sh ./
ENTRYPOINT [ "bash", "entrypoint.sh" ]

FROM prod AS test
COPY Makefile ./
RUN make test

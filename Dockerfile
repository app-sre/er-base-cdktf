
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.4 as BASE
USER 0

ENV HOME="/home/app"
ENV TF_VERSION="1.6.6"
ENV CDKTF_VERSION="0.20.8"
ENV NODEJS_VERSION="20"

ENV JSII_RUNTIME_PACKAGE_CACHE_ROOT=/tmp
ENV PIP_CACHE_DIR=/tmp

RUN mkdir -p ${HOME} && chmod 777 ${HOME} && \
    microdnf install -y python3.11 python3.11-pip.noarch && \
    update-alternatives --install /usr/bin/python3 python /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/pip3 pip /usr/bin/pip3.11 1

RUN INSTALL_PKGS="nodejs nodejs-nodemon nodejs-full-i18n npm findutils tar which unzip" && \
    microdnf -y module disable nodejs && \
    microdnf -y module enable nodejs:$NODEJS_VERSION && \
    microdnf -y --nodocs --setopt=install_weak_deps=0 install $INSTALL_PKGS && \
    node -v | grep -qe "^v$NODEJS_VERSION\." && echo "Found VERSION $NODEJS_VERSION" && \
    npm install --global cdktf-cli@${CDKTF_VERSION} && \
    microdnf clean all && \
    rm -rf /mnt/rootfs/var/cache/* /mnt/rootfs/var/log/dnf* /mnt/rootfs/var/log/yum.*

RUN curl -sfL https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip \
    -o terraform.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/terraform && \
    rm terraform.zip

WORKDIR ${HOME}
COPY requirements.txt .terraformrc ./
RUN python3 -m pip install --user -r requirements.txt

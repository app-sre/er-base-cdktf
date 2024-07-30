
FROM registry.access.redhat.com/ubi8/nodejs-18:1-81 as BASE
USER 0

ENV TF_VERSION="1.6.6"
ENV CDKTF_VERSION="0.20.8"

ENV JSII_RUNTIME_PACKAGE_CACHE_ROOT=/tmp

RUN \
    yum install -y yum-utils && \
    yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
    yum -y install terraform-${TF_VERSION} && \
    yum install -y python3.11 && \
    yum install -y python3.11-pip.noarch

USER 1001
COPY requirements.txt .terraformrc ./
RUN pip3 install -r requirements.txt
RUN npm install --global cdktf-cli@${CDKTF_VERSION}

FROM bitnami/minideb:stretch
MAINTAINER sre@bitnami.com

ARG jsonnet_version=0.11.2
ARG kubectl_version=1.12.0
ARG kubecfg_version=0.9.0

RUN install_packages jq make curl ca-certificates

RUN curl -sLo /usr/local/bin/jsonnet https://storage.googleapis.com/bitnami-jenkins-tools/jsonnet-${jsonnet_version}

RUN chmod +x /usr/local/bin/jsonnet

RUN curl -sLo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${kubectl_version}/bin/linux/amd64/kubectl
RUN chmod +x /usr/local/bin/kubectl

RUN curl -sLo /usr/local/bin/kubecfg https://github.com/ksonnet/kubecfg/releases/download/v${kubecfg_version}/kubecfg-linux-amd64
RUN chmod +x /usr/local/bin/kubecfg

RUN adduser --home /home/user --disabled-password --gecos User user

USER user
WORKDIR /home/user
CMD ["/bin/bash", "-l"]

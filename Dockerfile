FROM debian:bullseye-20211201

# Install docker, make, git, kubectl, helm
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      apt-transport-https \
      ca-certificates \
      gnupg2 \
      curl \
      tini \
      git \
      make \
      kmod \
      unzip \
      vim \
      nano \
      procps && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    echo "deb [arch=amd64] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y docker-ce && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

# Switch to use iptables instead of nftables (to match the CI hosts)
# TODO use some kind of runtime auto-detection instead if/when
# nftables is supported (https://github.com/moby/moby/issues/26824)
RUN update-alternatives --set iptables  /usr/sbin/iptables-legacy || true && \
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy || true && \
    update-alternatives --set arptables /usr/sbin/arptables-legacy || true

# Set up subuid/subgid so that "--userns-remap=default" works
# out-of-the-box.
RUN set -x && \
    addgroup --system dockremap && \
    adduser --system --ingroup dockremap dockremap && \
    echo 'dockremap:165536:65536' >> /etc/subuid && \
    echo 'dockremap:165536:65536' >> /etc/subgid

VOLUME /var/lib/docker
VOLUME /var/log/docker
EXPOSE 2375 2376
ENV container docker

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]


# install eksctl
# https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html
# version 0.52.0
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | \
    tar xz -C /tmp \
    && mv /tmp/eksctl /usr/local/bin

# install kubectl
# https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
# version 1.2
RUN curl -o /usr/local/bin/kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.20.4/2021-04-12/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl
## RUN chmod +x ./kubectl
## RUN mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
## RUN echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc

#install aws cli
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-install
# version 2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf ./aws && rm awscliv2.zip

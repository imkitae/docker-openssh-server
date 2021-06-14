FROM ghcr.io/linuxserver/baseimage-alpine:3.13

# set version label
ARG BUILD_DATE
ARG VERSION
ARG OPENSSH_RELEASE

# VERSION: 8.4_p1-r3-ls49
# BUILD_DATE: 2021-05-30T08:23:22+00:00
# OPENSSH_RELEASE: 8.4_p1-r3

LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

RUN \
 echo "**** install runtime packages ****" && \
 apk add --no-cache --upgrade \
	curl \
	logrotate \
	nano \
	sudo && \
 echo "**** install openssh-server ****" && \
 if [ -z ${OPENSSH_RELEASE+x} ]; then \
	OPENSSH_RELEASE=$(curl -sL "http://dl-cdn.alpinelinux.org/alpine/v3.13/main/x86_64/APKINDEX.tar.gz" | tar -xz -C /tmp \
	&& awk '/^P:openssh-server$/,/V:/' /tmp/APKINDEX | sed -n 2p | sed 's/^V://'); \
 fi && \
 apk add --no-cache \
	openssh-client==${OPENSSH_RELEASE} \
	openssh-server==${OPENSSH_RELEASE} \
	openssh-sftp-server==${OPENSSH_RELEASE} && \
 echo "**** setup openssh environment ****" && \
 sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config && \
 usermod --shell /bin/bash abc && \
 rm -rf \
	/tmp/*

# add local files
COPY /root /

# Install aws-cli v2 (https://stackoverflow.com/a/61268529)
ENV GLIBC_VER=2.31-r0
RUN apk --no-cache add \
        binutils \
    && curl -ksL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -ksLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
    && curl -ksLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
    && curl -ksLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk \
    && apk add --no-cache \
        glibc-${GLIBC_VER}.apk \
        glibc-bin-${GLIBC_VER}.apk \
        glibc-i18n-${GLIBC_VER}.apk \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && curl -ksL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
    && rm -rf \
        awscliv2.zip \
        aws \
        /usr/local/aws-cli/v2/*/dist/aws_completer \
        /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/*/dist/awscli/examples \
        glibc-*.apk \
    && apk --no-cache del \
        binutils \
    && rm -rf /var/cache/apk/*

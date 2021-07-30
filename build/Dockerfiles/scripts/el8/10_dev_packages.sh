#!/bin/sh -e

# Install necessary packages
dnf install -y epel-release
dnf install -y rpm-build rpmdevtools ruby-devel rpm-devel rpm-sign
dnf install -y util-linux openssl augeas-libs createrepo genisoimage git gnupg2 libicu-devel libxml2 libxml2-devel libxslt libxslt-devel which ruby-devel
dnf -y install scl-utils python2-virtualenv python3-virtualenv fontconfig dejavu-sans-fonts dejavu-sans-mono-fonts dejavu-serif-fonts dejavu-fonts-common libjpeg-devel zlib-devel openssl-devel
dnf install -y libyaml glibc-headers autoconf gcc gcc-c++ glibc-devel readline-devel libffi-devel automake libtool bison sqlite-devel pinentry

# Install helper packages
dnf install -y rubygems vim-enhanced jq

# Install for python/simp-doc pkg:build
dnf install -y dejavu-fonts-common dejavu-sans-fonts dejavu-sans-mono-fonts dejavu-serif-fonts fontconfig libjpeg-devel python3-pip python3-virtualenv zlib-devel

# Install SSH for CI testing
dnf -y install initscripts
if [ -d /etc/ssh ]; then /bin/cp -a /etc/ssh /root; fi
dnf -y install openssh-server
if [ -d /root/ssh ]; then /bin/cp -a /root/ssh /etc && /bin/rm -rf /root/ssh; fi

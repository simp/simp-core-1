# This version of CentOS is needed for the SELinux context builds
# After building, you will probably want to mount your ISO directory using
# something like the following:
#   * docker run -v $PWD/ISO:/ISO:Z -it <container ID>
#
# If you want to save your container for future use, you use use the `docker
# commit` command
#   * docker commit <running container ID> el6_build
#   * docker run -it el6_build
FROM centos:6.6
ENV container docker

# Fix issues with overlayfs
RUN yum clean all
RUN yum install -y sudo curl ntpdate
RUN rm -f /var/lib/rpm/__db*
RUN yum clean all
RUN yum install -y yum-plugin-ovl || :
RUN yum install -y yum-utils

# Prep for buidling aginst the oldest SELinux packages
RUN yum-config-manager --disable \*
RUN echo -e "[legacy]\nname=Legacy\nbaseurl=http://vault.centos.org/6.6/os/x86_64\ngpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-6\ngpgcheck=1" > /etc/yum.repos.d/legacy.repo
RUN cd /root; yum -x yum -x python-urlgrabber downgrade -y *

# Work around bug https://bugzilla.redhat.com/show_bug.cgi?id=1217477
# This does *not* update the SELinux packages, so it is safe
RUN yum --enablerepo=updates --enablerepo=base update -y git curl nss

RUN yum install -y selinux-policy-targeted selinux-policy-devel policycoreutils policycoreutils-python

# Ensure that the 'build_user' can sudo to root for RVM
RUN echo 'Defaults:build_user !requiretty' >> /etc/sudoers
RUN echo 'build_user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
RUN useradd -b /home -G wheel -m -c "Build User" -s /bin/bash -U build_user
RUN rm -rf /etc/security/limits.d/*.conf

# Install necessary packages
RUN yum-config-manager --enable extras
RUN yum install -y epel-release
RUN yum install -y openssl util-linux rpm-build augeas-devel createrepo genisoimage git gnupg2 libicu-devel libxml2 libxml2-devel libxslt libxslt-devel rpmdevtools which ruby-devel rpm-sign acl
RUN yum -y install centos-release-scl python-pip python-virtualenv fontconfig dejavu-sans-fonts dejavu-sans-mono-fonts dejavu-serif-fonts dejavu-fonts-common libjpeg-devel zlib-devel
RUN yum install -y libyaml-devel glibc-headers autoconf gcc gcc-c++ glibc-devel readline-devel libffi-devel openssl-devel automake libtool bison sqlite-devel tar
RUN yum-config-manager --enable rhel-server-rhscl-6-rpms
RUN yum -y install python27

# Install helper packages
RUN yum install -y rubygems vim-enhanced jq

# Set up RVM
RUN runuser build_user -l -c "echo 'gem: --no-ri --no-rdoc' > .gemrc"

# Do our best to get one of the keys from at one of the servers, and to
# trust the right ones if the GPG keyservers return bad keys
#
# These are the keys we want:
#
#  409B6B1796C275462A1703113804BB82D39DC0E3 # mpapis@gmail.com
#  7D2BAF1CF37B13E2069D6956105BD0E739499BDB # piotr.kuczynski@gmail.com
#
# See:
#   - https://rvm.io/rvm/security
#   - https://github.com/rvm/rvm/blob/master/docs/gpg.md
#   - https://github.com/rvm/rvm/issues/4449
#   - https://github.com/rvm/rvm/issues/4250
#   - https://seclists.org/oss-sec/2018/q3/174
#
# NOTE (mostly to self): In addition to RVM's documented procedures,
# importing from https://keybase.io/mpapis may be a practical
# alternative for 409B6B1796C275462A1703113804BB82D39DC0E3:
#
#    curl https://keybase.io/mpapis/pgp_keys.asc | gpg2 --import
#
RUN runuser build_user -l -c "{ gpg2 --keyserver hkp://pgp.mit.edu --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 || gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3; }; key1=$?; { gpg2 --keyserver hkp://pgp.mit.edu --recv-keys 7D2BAF1CF37B13E2069D6956105BD0E739499BDB || gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 7D2BAF1CF37B13E2069D6956105BD0E739499BDB ; }; key2=$? ; [ \"$key1\" -eq 0 ] || [ \"$key2\" -eq 0 ] || curl -sSL https://rvm.io/mpapis.asc | gpg --import -"
RUN runuser build_user -l -c "gpg2 --refresh-keys"
RUN runuser build_user -l -c "echo 409B6B1796C275462A1703113804BB82D39DC0E3:6: | gpg2 --import-ownertrust; key1=$?; echo 7D2BAF1CF37B13E2069D6956105BD0E739499BDB:6: | gpg2 --import-ownertrust; key2=$?; [ \"$key1\" -eq 0 ] || [ \"$key2\" -eq 0 ]"
RUN runuser build_user -l -c "curl -sSL https://raw.githubusercontent.com/rvm/rvm/stable/binscripts/rvm-installer -o rvm-installer && curl -sSL https://raw.githubusercontent.com/rvm/rvm/stable/binscripts/rvm-installer.asc -o rvm-installer.asc && gpg2 --verify rvm-installer.asc rvm-installer && bash rvm-installer"
RUN runuser build_user -l -c "rvm install 2.4.4 --disable-binary"
RUN runuser build_user -l -c "rvm use --default 2.4.4"
RUN runuser build_user -l -c "rvm all do gem install bundler"

# Check out a copy of simp-core for building
RUN runuser build_user -l -c "git clone https://github.com/simp/simp-core"

# Prep the build space
RUN runuser build_user -l -c "cd simp-core; bundle install"

# Drop into a shell for building
CMD /bin/bash -c "su -l build_user"

#!/bin/bash
set -eu -o pipefail

SIMP_BUILD_distro=CentOS,8.3,x86_64
METHOD=pinned
DISTRO_BUILD_DIR="$PWD/build/distributions/CentOS/8/x86_64/"
ISO_UNPACK_TARGET_DIR="$DISTRO_BUILD_DIR/SIMP_ISO_STAGING"
PATH_TO_ISO=/pulp/ISOs/CentOS-8.3.2011-x86_64-dvd1.iso
ISO_VERSION=8.3.2011
ISOINFO=isoinfo
ISO_UNPACK_MERGE=no
GPGKEY_NAME=dev
BUILD_DOCS=no


[[ "${SKIP_DEPS:-no}" == yes ]]   || bundle exec rake deps:clean[$METHOD]
[[ "${SKIP_DEPS:-no}" == yes ]]   || bundle exec rake deps:checkout[$METHOD]
[[ "${SKIP_UNPACK:-no}" == yes ]] || bundle exec rake unpack[${PATH_TO_ISO},${ISO_UNPACK_MERGE},${ISO_UNPACK_TARGET_DIR},$ISOINFO,$ISO_VERSION]

# TODO:
#

#  - [ ] SIMP-XXXX  Remove all repodirs from all $ISO_UNPACK_TARGET_DIR/*/
#  - [ ] SIMP-XXXX  Copy over all mirrored pulp repodirs into $ISO_UNPACK_TARGET_DIR/


[[ "${SKIP_TAR:-no}" == yes ]]    || bundle exec rake tar:build[$GPGKEY_NAME,$BUILD_DOCS]
# Environment not suitable: Unable to find directory '/home/build_user/simp-core/build/distributions/CentOS/8/x86_64/DVD/isolinux'
# /home/build_user/.rvm/gems/ruby-2.6.6/gems/simp-rake-helpers-5.12.1/lib/simp/rake/build/pkg.rb:1030:in `block in check_dvd_env'
#
# ^^ - [X] add isolinux directory for EL8 to simp-core
#       - NOTE: This will definitely be broken for the first few runs
#       - TODO: Track ISO kickstart problems separately
#    - [ ] FIXME: tarred rpms are in noarch subdirectory: ./SIMP/noarch/pupmod-simp-svckill-3.6.2-0.noarch.rpm

# TODO iso:build
#   - [X] bump version in simp.spec
#   - [ ] FIXME: remove `createrepo -p` in iso:build
#   - [ ] FIXME: run pkg:checksig on ALL packages with all keys
#   - [ ] Remove /var/www/yum/SIMP to o
#   - [ ] Place all GPG keys in /GPGPKEYS on ISO
#   - [ ] TODO: Jira ticket to decide how to handle upgrades

build/distributions/CentOS/8/x86_64/DVD_Overlay/SIMP-DVD-CentOS-6.5.0-1.el8.tar.gz

[[ "${SKIP_ISO:-no}" == yes ]]    || bundle exec rake iso:build[$GPGKEY_NAME,$BUILD_DOCS]


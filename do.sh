#!/bin/bash
set -eu -o pipefail

SIMP_BUILD_distro=CentOS,8.3,x86_64
METHOD=pinned
DISTRO_BUILD_DIR="$PWD/build/distributions/CentOS/8/x86_64/"
PATH_TO_ISO=/pulp/ISOs/CentOS-8.3.2011-x86_64-dvd1.iso
ISO_UNPACK_TARGET_BASE="$DISTRO_BUILD_DIR/SIMP_ISO_STAGING"

# TODO it's a little weird there's no dash betwen CentOS and 8 in the directory
ISO_UNPACK_TARGET_DIR="$ISO_UNPACK_TARGET_BASE/$(basename "$PATH_TO_ISO" -dvd1.iso | sed -e 's/-//' )"


ISO_VERSION=8.3.2011
ISOINFO=isoinfo
ISO_UNPACK_MERGE=no
GPGKEY_NAME=dev
BUILD_DOCS=no
SIMP_TARBALL=build/distributions/CentOS/8/x86_64/DVD_Overlay/SIMP-DVD-CentOS-6.6.0-Alpha1.el8.tar.gz

LOCAL_REPOS_BASE_DIR=/pulp/_download_path/build-6-6-0-centos-8-x86-64-test-advrpm-copy-resolution-fails


[[ "${SKIP_CLEAN:-yes}" == yes ]]   || bundle exec rake deps:clean[$METHOD]
[[ "${SKIP_CLEAN:-yes}" == yes ]]   || bundle exec rake clean
[[ "${SKIP_CLEAN:-yes}" == yes ]]   || bundle exec rake clobber

[[ "${SKIP_DEPS:-no}" == yes ]]   || bundle exec rake deps:checkout[$METHOD]

# Build RPMs
[[ "${SKIP_TAR:-no}" == yes ]]    || bundle exec rake tar:build[$GPGKEY_NAME,$BUILD_DOCS]


# TODO:
#
#  - [x] SIMP-XXXX  Remove all repodirs from all $ISO_UNPACK_TARGET_BASE/*/
#  - [ ] SIMP-XXXX  Copy over all mirrored pulp repodirs into $ISO_UNPACK_TARGET_DIR/
[[ "${SKIP_UNPACK:-no}" == yes ]] || bundle exec rake unpack[${PATH_TO_ISO},${ISO_UNPACK_MERGE},${ISO_UNPACK_TARGET_BASE},$ISOINFO,$ISO_VERSION]


[[ "${SKIP_STAGE:-no}" == yes ]] || bundle exec rake iso:stage:tarball[$SIMP_TARBALL,$ISO_UNPACK_TARGET_DIR]

[[ "${SKIP_STAGE:-no}" == yes ]] || bundle exec rake iso:stage:local_repos[$LOCAL_REPOS_BASE_DIR,$ISO_UNPACK_TARGET_DIR]


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
#   - [ ] Ensure .treeinfo has correct variants



# unpacks tarball into 
[[ "${SKIP_ISO:-no}" == yes ]]    || bundle exec rake iso:build2[$SIMP_TARBALL,$ISO_UNPACK_TARGET_DIR]

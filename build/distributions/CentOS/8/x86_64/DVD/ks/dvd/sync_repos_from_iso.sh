#!/bin/bash

# Some nonsense to try and re-mount the DVD
if [ -b /dev/cdrom ]; then
  if [ ! -d "$SOURCE" ]; then
    mkdir "$SOURCE"
  fi
  if [ ! -d "$SOURCE/Packages" ]; then
    mount -t iso9660 -o ro /dev/cdrom "$SOURCE"
  fi
fi

if [ -f "$SYSIMAGE/opt/puppetlabs/puppet/bin/facter" ]; then
  facter="chroot '$SYSIMAGE' /opt/puppetlabs/puppet/bin/facter"
else
  facter="chroot '$SYSIMAGE' facter"
fi

# Get the Linux distribution
ostype="$($facter operatingsystem)"
rhversion="$($facter operatingsystemrelease)"
majrhversion="$($facter operatingsystemmajrelease)"
htype="$($facter architecture)"

# Save the current umask and directory
UMASKSAVE="$(umask)"
umask 0002
pushd .

# Detect all RPM repositories
i=0
source_repo_dirs=()
while IFS= read -r -d $'\0' repo_path
  do source_repo_dirs[i++]="$repo_path"
done < <(find "$SOURCE" -maxdepth 4 -type f \
  -name repomd.xml -wholename '*/repodata/repomd.xml' \
  -exec sh -c 'printf "%s\0" "$(dirname "$(dirname "{}")")"' \;)

postinstall_err_log="$SYSIMAGE/root/postinstall.err"
yum_root=/var/www/yum
os_maj_arch_dirs="$ostype/$rhversion/$htype"
repos_root="${yum_root}/${os_maj_arch_dirs}"
sys_repos_root="${SYSIMAGE}${repos_root}"

if ! cd "$SOURCE"; then
  # --------- FIXME FIXME FIXME A01 BEGIN: ----------------------------------------
  #  Review these instructions after we determine what the new process should be
  # ------------------------------------------------------------------------------
  echo "There was a problem changing directory to ${SOURCE}, the DVD will not be copied to disk." | tee "$postinstall_err_log"
  echo "Run the following commands once the install has completed:" | tee -a "$postinstall_err_log"
  echo -e "\tyadday yadda yadda" | tee -a "$postinstall_err_log"
  # --------- FIXME FIXME FIXME A01 END: ----------------------------------------
else
  mkdir -p "$sys_repos_root"
  mkdir -p "/var/www/yum/SIMP"

  cp -a "$SOURCE/ks" "$SYSIMAGE/var/www/"
  cp -a "$SOURCE/GPGKEYS" "$SYSIMAGE/var/www/yum/SIMP/"

  for source_repo_dir in "${source_repo_dirs[@]}"; do
    repo_dirname="$(basename "$source_repo_dir")"
    target_repo_dir="$sys_repos_root/$repo_dirname"
    cp -a "$source_repo_dir/*" "$target_repo_dir/"  # try this, otherwise use dnf reposync --download-metadata
  done
fi

# TODO: Decide if this condition is necessary during an OS install
if [ ! -d "$SYSIMAGE/var/www/yum/$ostype/$majrhversion" ]; then
  cd "$SYSIMAGE/var/www/yum/$ostype"
  ln -sf $rhversion $majrhversion
  cd -
fi

popd
umask "$UMASKSAVE"
umount "$SOURCE"

chown -R root:48 "$SYSIMAGE/var/www"
chmod -R u=rwX,g=rX,o-rwx "$SYSIMAGE/var/www"

#!/bin/bash

# If we dropped a LUKS key-file, we need to copy it into place.
if [ -f /boot/disk_creds ]; then
  cp /boot/disk_creds "$SYSIMAGE/etc/.cryptcreds"
  chown root:root "$SYSIMAGE/etc/.cryptcreds"
  chmod 400 "$SYSIMAGE/etc/.cryptcreds"

  crypt_disk=`cat /boot/crypt_disk`
  for x in /dev/$crypt_disk*; do
    if `cryptsetup isLuks $x`; then
      crypt_partition="$x"
      break
    fi
  done

  if [ -z "$crypt_partition" ]; then
    echo "Error: Could not find the encrypted partition"
    exit 1
  fi

  exec < /dev/tty6 > /dev/tty6 2> /dev/tty6
  chvt 6

  echo "Updating the LUKS keys, this may take some time...."

  # We need to make sure our keyfile lands in slot 0 and EL6 doesn't have the
  # luksChangeKey command
  cryptsetup luksAddKey --key-slot 1 --key-file /boot/disk_creds "$crypt_partition" /boot/disk_creds
  cryptsetup luksKillSlot --key-file /boot/disk_creds "$crypt_partition" 0

  cryptsetup luksAddKey --key-slot 0 --key-file /boot/disk_creds "$crypt_partition" /boot/disk_creds
  cryptsetup luksKillSlot --key-file /boot/disk_creds "$crypt_partition" 1

  # Modify the crypttab file
  crypt_uuid="$(cryptsetup luksDump "${crypt_partition}" | grep UUID | sed 's/[[:space:]]\+/ /g' | cut -f2 -d' ')"

  chvt 1
  exec < /dev/tty1 > /dev/tty1 2> /dev/tty1

  # If we got here, and this is blank, fail hard!
  if [ -z "$crypt_uuid" ]; then
    echo "Error: Could not find crypt_uuid"
    exit 1
  fi

  echo "luks-${crypt_uuid} UUID=${crypt_uuid} /etc/.cryptcreds luks" > "$SYSIMAGE/etc/crypttab"
fi

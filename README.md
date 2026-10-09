# Project

## NixOS Install

Boot USB NixOS, prepare fat32 BOOT (boot flag) and ext4 nixos partitions with gparted

Hosts: `asus` and `legion` (`hosts/`)

```sh
sudo -i
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=0077 /dev/disk/by-label/BOOT /mnt/boot
findmnt /mnt
findmnt /mnt/boot
git clone https://github.com/FyorDev/nixos.git
cd nixos
```

If disk/partitions changed

```sh
nixos-generate-config --root /mnt --show-hardware-config > hosts/<host>/hardware-configuration.nix
git add hosts/<host>/hardware-configuration.nix
```

```sh
nixos-install --flake .#<host>
nixos-enter --root /mnt -c 'passwd <user>'
cp -r ../nixos /mnt/home/<user>/nixos
nixos-enter --root /mnt -c 'chown -R <user>:users /home/<user>/nixos'
mkdir -p /mnt/home/<user>/.ssh
cp <private-key> <public-key> /mnt/home/<user>/.ssh/
cat <public-key> >> /mnt/home/<user>/.ssh/authorized_keys
nixos-enter --root /mnt -c 'chown -R <user>:users /home/<user>/.ssh && chmod 700 /home/<user>/.ssh && chmod 600 /home/<user>/.ssh/* && chmod 644 /home/<user>/.ssh/*.pub'
reboot
```

Rebuild with `just switch`, or force pull and rebuild with `just sync`.

Add `background.png` or `background.jpg` to the root and rebuild.

## Release

```sh
just release --dry v0.0.0 "title"
just release v0.0.0 "title"
```

## Shortcuts

`fish`: Ctrl+N neovim  
`fzf`: Ctrl+R history Ctrl+T filepath Alt+C directory

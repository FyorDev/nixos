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
nixos-enter --root /mnt -c 'passwd fyor'
cp -r ../nixos /mnt/home/fyor/nixos
nixos-enter --root /mnt -c 'chown -R fyor:users /home/fyor/nixos'
mkdir -p /mnt/home/fyor/.ssh
cp <private-key> <public-key> /mnt/home/fyor/.ssh/
cat <public-key> >> /mnt/home/fyor/.ssh/authorized_keys
nixos-enter --root /mnt -c 'chown -R fyor:users /home/fyor/.ssh && chmod 700 /home/fyor/.ssh && chmod 600 /home/fyor/.ssh/* && chmod 644 /home/fyor/.ssh/*.pub'
reboot
```

Rebuild with `just switch`, or force pull and rebuild with `just sync`.

## Release

```sh
just release --dry v0.0.0 "title"
just release v0.0.0 "title"
```

## Shortcuts

`fish`: Ctrl+N neovim  
`fzf`: Ctrl+R history Ctrl+T filepath Alt+C directory

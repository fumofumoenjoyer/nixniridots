# nix dotfiles
## Actualizar
```
cd nix-dotfiles
```
```
sudo nix flake update
```
```
sudo nixos-rebuild switch --flake
```
### Or
```
cd
cd nix-dotfiles
sudo nix flake update
sudo nixos-rebuild switch --flake
cd
```

## Migración a ZFS

### Paso 1: Arrancar y Particionar

Inicia el PC desde el USB. Abre una terminal (`sudo -i` para ser root) y localiza tu disco (ej. `/dev/nvme1n1` o `/dev/sda`) con `lsblk`.

Vamos a suponer que tu disco es `/dev/nvme1n1`.

1. **Limpiar disco:**
```bash
wipefs -a /dev/nvme1n1

```


2. **Crear particiones (EFI + ZFS):**
* Partición 1 (Boot/EFI): 1GB, FAT32.
* Partición 2 (ZFS): El resto del disco.


```bash
parted /dev/nvme1n1 -- mklabel gpt
parted /dev/nvme1n1 -- mkpart ESP fat32 1MB 1GB
parted /dev/nvme1n1 -- set 1 esp on
parted /dev/nvme1n1 -- mkpart primary 1GB 100%

```


3. **Formatear la Boot:**
```bash
mkfs.vfat -n BOOT /dev/nvme1n1p1

```



---

### Paso 2: Crear el Pool y los Datasets

Aquí creamos la "magia" de ZFS. Usaremos opciones estándar de rendimiento (`ashift=12` para SSDs, compresión `zstd`).

1. **Crear el Pool (zroot):**
```bash
zpool create -f \
  -o ashift=12 \
  -O compression=zstd \
  -O acltype=posixacl \
  -O xattr=sa \
  -O encryption=aes-256-gcm \
  -O keyformat=passphrase \
  -O keylocation=prompt \
  -O mountpoint=none \
  zroot /dev/nvme0n1p2

```


2. **Crear Datasets (Discos virtuales):**
Separamos el sistema (`root`), el usuario (`home`) y la tienda de Nix (`nix`) para gestionarlos mejor.
```bash
# Sistema Raíz (se borra fácil si quieres)
zfs create -o mountpoint=legacy zroot/root

# Datos de usuario (persistentes y valiosos)
zfs create -o mountpoint=legacy zroot/home

# Tienda Nix (no necesita backup, se regenera)
zfs create -o mountpoint=legacy zroot/nix

```



---

### Paso 3: Montar y Preparar Instalación

NixOS se instala en `/mnt`.

1. **Montar los datasets:**
```bash
mount -t zfs zroot/root /mnt

mkdir -p /mnt/{nix,home,boot}

mount -t zfs zroot/nix /mnt/nix
mount -t zfs zroot/home /mnt/home

# Montar la partición EFI
mount /dev/nvme1n1p1 /mnt/boot

```


2. **Clonar tu configuración:**
Necesitas `git` en el instalador.
```bash
nix-shell -p git
git clone https://github.com/TU_USUARIO/nix-dotfiles.git /mnt/etc/nixos

```


*(O si la guardaste en un USB, cópiala a esa ruta).*

---

### Paso 4: Actualizar Hardware Config (¡IMPORTANTE!)

Como acabas de formatear, los UUIDs de tus discos han cambiado. Tu `hardware-configuration.nix` viejo ya no sirve.

1. Genera uno nuevo basado en lo que acabamos de montar:
```bash
nixos-generate-config --root /mnt

```


*Esto creará un archivo nuevo en `/mnt/etc/nixos/hardware-configuration.nix`.*
2. Revisa que detecte ZFS:
```bash
cat /mnt/etc/nixos/hardware-configuration.nix

```


Deberías ver `fileSystems."/" = { device = "zroot/root"; fsType = "zfs"; };`.

---

...
### Paso 5: Instalar

Ahora lanzas el comando mágico. Como usas Flakes, especificamos el usuario (`#FumOS-KDE`).

```bash
nixos-install --flake /mnt/etc/nixos#FumOS-KDE

```

Si todo sale bien, te pedirá contraseña de root y terminará.
**Reinicia**, quita el USB y deberías estar en tu nuevo sistema ZFS.

---

### Paso 6: Post-Instalación (Mantenimiento)

Una vez dentro de tu nuevo sistema ZFS, añade esto a tu `configuration.nix` para que ZFS se mantenga sano automáticamente:

```nix
  services.zfs.autoScrub.enable = true; # Revisa errores de datos cada semana
  services.zfs.trim.enable = true;      # Mantiene el SSD rápido

```

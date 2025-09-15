# Mise en oeuvre de l'HTTPS sur un serveur web
# Utilisation d'une autorité de certification interne

## 1. Préparation de la machine CA
- Configuration IP : /etc/network/interfaces
```bash
allow-hotplug ens33
iface ens33 inet static
        address 172.16.0.20/24
        gateway 172.16.0.254
```
- Installation d'openssl
```bash
apt update && sudo apt upgrade -y
apt install openssl
```
## 2. configuration d'openssl
- Editez le fichier /etc/ssl/openssl.cnf
```bash
dir = ./sodecaf
```
- Création des dossiers et fichiers nécessaires
```bash
mkdir /etc/ssl/sodecaf
cd /etc/ssl/sodecaf/
touch index.txt
echo "01" > serial
  ```
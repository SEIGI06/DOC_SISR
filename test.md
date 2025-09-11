# Documentation : Serveur Web complet sur Debian 12 (Apache, HTTPS, Sécurisation)

## Présentation

Ce document décrit une installation simple et efficace d’un serveur web Apache sur Debian 12, avec HTTPS via Let's Encrypt et des mesures de sécurisation de base (pare-feu, en-têtes de sécurité, Fail2ban).

## Prérequis

- Accès sudo sur une Debian 12 à jour
- Nom de domaine pointant vers l’adresse IP publique du serveur (A/AAAA)
- Ports ouverts sur votre hébergeur/pare-feu réseau : 80/TCP (HTTP), 443/TCP (HTTPS)
- Heure système correcte (service `systemd-timesyncd` activé)
- Optionnel : IPv6 configurée si utilisée

## Installation

```bash
# 1) Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# 2) Installer Apache
sudo apt install apache2 -y

# 3) Activer et vérifier le service
sudo systemctl enable --now apache2
systemctl status apache2 | cat
```

## Configuration

Les hôtes virtuels se déclarent dans `/etc/apache2/sites-available/`. Exemple minimal HTTP pour `exemple.com` :

```apache
<VirtualHost *:80>
    ServerName exemple.com
    ServerAlias www.exemple.com
    DocumentRoot /var/www/exemple

    <Directory /var/www/exemple>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/exemple_error.log
    CustomLog ${APACHE_LOG_DIR}/exemple_access.log combined
</VirtualHost>
```

Activer le site et recharger :

```bash
sudo mkdir -p /var/www/exemple
echo "OK" | sudo tee /var/www/exemple/index.html
sudo a2ensite exemple.conf || sudo ln -s /etc/apache2/sites-available/exemple.conf /etc/apache2/sites-enabled/
sudo systemctl reload apache2
```

## HTTPS

### Option A — Let's Encrypt (recommandé en production)

Installer Certbot et le module Apache, puis émettre le certificat pour `exemple.com` :

```bash
sudo apt install certbot python3-certbot-apache -y
sudo certbot --apache -d exemple.com -d www.exemple.com
```

Tester le renouvellement automatique :

```bash
sudo certbot renew --dry-run
```

### Option B — Certificat auto-signé (pour tests/lab)

1. Installer OpenSSL et activer SSL pour Apache :

```bash
sudo apt install openssl -y
sudo a2enmod ssl
```

1. Générer une clé privée et un certificat auto-signé (1 an) :

```bash
sudo openssl req -x509 -nodes -newkey rsa:4096 \
  -keyout /etc/ssl/private/exemple.key \
  -out /etc/ssl/certs/exemple.crt \
  -days 365 \
  -subj "/C=FR/ST=IDF/L=Paris/O=Lab/CN=exemple.com"
sudo chmod 600 /etc/ssl/private/exemple.key
```

1. Créer le vHost 443 et rediriger le HTTP vers HTTPS :

```apache
<VirtualHost *:80>
    ServerName exemple.com
    Redirect / https://exemple.com/
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName exemple.com
    DocumentRoot /var/www/exemple

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/exemple.crt
    SSLCertificateKeyFile /etc/ssl/private/exemple.key

    <Directory /var/www/exemple>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/exemple_ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/exemple_ssl_access.log combined
</VirtualHost>
</IfModule>
```

Activer le site SSL et recharger :

```bash
sudo a2ensite exemple-ssl.conf || true
sudo systemctl reload apache2
```

Note : les navigateurs afficheront un avertissement car le certificat n’est pas émis par une AC publique. Pour le supprimer, importez le certificat (ou mieux, une AC interne) dans le magasin de confiance des clients.

### Option C — Autorité de certification interne (AC privée)

Permet d’émettre des certificats reconnus en interne sans passer par une AC publique.

1. Créer une AC racine (clé et certificat racine)

```bash
sudo mkdir -p /root/ca/{certs,crl,newcerts,private}
sudo chmod 700 /root/ca/private
sudo touch /root/ca/index.txt && echo 1000 | sudo tee /root/ca/serial

# Clé privée de l'AC (protégez-la !) et certificat racine (10 ans)
sudo openssl genrsa -out /root/ca/private/ca.key 4096
sudo openssl req -x509 -new -nodes -key /root/ca/private/ca.key -sha256 -days 3650 \
  -subj "/C=FR/ST=IDF/L=Paris/O=MonEntreprise/CN=MonEntreprise Root CA" \
  -out /root/ca/certs/ca.crt
```

1. Générer un certificat serveur signé par l’AC interne

```bash
# Clé privée serveur et CSR
sudo openssl genrsa -out /etc/ssl/private/exemple.key 4096
sudo openssl req -new -key /etc/ssl/private/exemple.key \
  -subj "/C=FR/ST=IDF/L=Paris/O=MonEntreprise/CN=exemple.com" \
  -out /tmp/exemple.csr

# Fichier d'extensions pour inclure les SAN
cat << 'EOF' | sudo tee /tmp/exemple_ext.cnf
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = exemple.com
DNS.2 = www.exemple.com
EOF

# Signature par l'AC interne (2 ans)
sudo openssl x509 -req -in /tmp/exemple.csr -CA /root/ca/certs/ca.crt -CAkey /root/ca/private/ca.key \
  -CAcreateserial -out /etc/ssl/certs/exemple.crt -days 730 -sha256 -extfile /tmp/exemple_ext.cnf
```

1. Configurer Apache avec le certificat signé par l’AC interne

```apache
<VirtualHost *:443>
    ServerName exemple.com
    DocumentRoot /var/www/exemple

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/exemple.crt
    SSLCertificateKeyFile /etc/ssl/private/exemple.key
    SSLCACertificateFile /root/ca/certs/ca.crt
</VirtualHost>
```

1. Distribuer la racine de l’AC aux clients internes

- Linux (Debian/Ubuntu) :

```bash
sudo cp /root/ca/certs/ca.crt /usr/local/share/ca-certificates/monentreprise-root-ca.crt
sudo update-ca-certificates
```

- Windows : importer `ca.crt` dans Autorités de certification racines de confiance (via MMC ou GPO).

- Navigateurs/Java : importer dans le magasin de certificats spécifique si nécessaire.

## Sécurisation

- Mises à jour régulières et sécurité :

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

- Pare-feu UFW (autoriser HTTP/HTTPS) :

```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow "Apache Full"
sudo ufw enable
sudo ufw status
```

- En-têtes de sécurité (nécessite `headers`) :

```bash
sudo a2enmod headers
sudo tee /etc/apache2/conf-available/security-headers.conf > /dev/null <<'EOF'
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set Referrer-Policy "no-referrer-when-downgrade"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Content-Security-Policy "default-src 'self'"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
</IfModule>
EOF
sudo a2enconf security-headers
sudo systemctl reload apache2
```

- Désactiver modules/infos inutiles :

```bash
sudo a2dismod status autoindex
sudo systemctl reload apache2
```

- Installer Fail2ban :

```bash
sudo apt install fail2ban -y
```

Configuration minimale Nginx/Apache non requise par défaut pour Fail2ban, mais vous pouvez créer `/etc/fail2ban/jail.local` pour affiner.

## Vérification

- Accéder à `http://exemple.com` puis `https://exemple.com`
- Vérifier les services :

```bash
systemctl status apache2 | cat
sudo ufw status
systemctl status fail2ban | cat
```

## Conclusion

- Debian 12 à jour, Apache installé et activé
- HTTPS via Let's Encrypt opérationnel avec renouvellement automatique
- Mesures de base appliquées : UFW, en-têtes de sécurité, Fail2ban, mises à jour automatiques

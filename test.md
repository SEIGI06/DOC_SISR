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

## HTTPS (Let's Encrypt)
Installer Certbot et le module Apache, puis émettre le certificat pour `exemple.com` :
```bash
sudo apt install certbot python3-certbot-apache -y
sudo certbot --apache -d exemple.com -d www.exemple.com
```
Tester le renouvellement automatique :
```bash
sudo certbot renew --dry-run
```

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
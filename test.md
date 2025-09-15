# Mise en oeuvre de l'HTTPS sur un serveur web
# Utilisation d'une autoritÃ© de certification interne

## 1. PrÃ©paration de la machine CA
- Configuration IP : /etc/network/interfaces
![Capture configuration IP de la CA](images_resized/ca_ip_config.png)
```bash
allow-hotplug ens33
iface ens33 inet static
        address 172.16.0.20/24
        gateway 172.16.0.254
```
- Installation d'openssl
![Installation d'OpenSSL sur la CA](images_resized/ca_ip_config.png%20—%20Configuration%20IP%20de%20la%20CA.png)
```bash
apt update && sudo apt upgrade -y
apt install openssl
```
## 2. configuration d'openssl
- Editez le fichier /etc/ssl/openssl.cnf
![Ã‰dition de openssl.cnf sur la CA](images_resized/ca_openssl_cnf_edit.png)
```bash
dir = /etc/ssl/sodecaf
certificate = $dir/certs/cacert.pem
```
- CrÃ©ation des dossiers et fichiers nÃ©cessaires
![Arborescence CA initiale](images_resized/ca_tree_init.png)
```bash
mkdir /etc/ssl/sodecaf
cd /etc/ssl/sodecaf/
mkdir certs
mkdir private
mkdir newcerts
touch index.txt
echo "01" > serial
```
## 3. GÃ©nÃ©ration du certificat de l'autoritÃ© de certification
- CrÃ©ation de la clÃ© privÃ©e de l'autoritÃ© de certification
![GÃ©nÃ©ration de la clÃ© privÃ©e de la CA](images_resized/ca_key_gen.png)
```bash
openssl genrsa -des3 -out /etc/ssl/sodecaf/private/cakey.pem 4096
chmod 400 /etc/ssl/sodecaf/private/cakey.pem
```
- CrÃ©ation du certificat auto-signÃ© de l'autoritÃ© de certification
![Certificat auto-signÃ© CA gÃ©nÃ©rÃ©](images_resized/ca_self_signed_created.png)
```bash
cd /etc/ssl/sodecaf/
openssl req -new -x509 -days 1825 -key private/cakey.pem -out certs/cacert.pem
```
## 4. GÃ©nÃ©ration du certificat du serveur web
On travaille sur le serveur web1
- Editez le fichier /etc/ssl/openssl.cnf
![Ã‰dition de openssl.cnf sur le serveur web](images_resized/srv_openssl_cnf_edit.png)
```bash
dir = /etc/ssl
```
- CrÃ©ation de la clÃ© privÃ©e du serveur web
![CrÃ©ation de la clÃ© privÃ©e serveur](images_resized/srv_key_gen.png)
```bash
openssl genrsa -out /etc/ssl/private/srvwebkey.pem 4096
```
- CrÃ©ation du fichier de demande de certificat
![CrÃ©ation de la CSR serveur](images_resized/srv_csr_create.png)
```bash
openssl req -new -key private/srvwebkey.pem -out certs/srvwebkey_dem.pem
```
- Copie du fichier de demande de certificat sur la machine CA
![Transfert de la CSR vers la CA](images_resized/srv_csr_scp_to_ca.png)
```bash
scp srvwebkey_dem.pem etudiant@172.16.0.20:/home/etudiant/
```
On travaille sur le serveur CA
- CrÃ©ation du certificat
![Signature du certificat serveur par la CA](images_resized/ca_sign_server_cert.png)
```bash
openssl ca -policy policy_anything -out /etc/ssl/sodecaf/certs/srvwebcert.pem -infiles /home/etudiant/srvwebkey_dem.pem 
```
- Copie du certificat sur le serveur web
![Retour du certificat signÃ© vers le serveur](images_resized/ca_cert_scp_back.png)
```bash
scp srvwebcert.pem etudiant@172.16.0.10:/home/etudiant
```
On travaille sur le serveur web srv-web1
- DÃ©placement et changement de propriÃ©taire du certificat
![Placement des certificats cÃ´tÃ© serveur](images_resized/srv_place_certs.png)
```bash
mv /home/etudiant/srvwebcert.pem /etc/ssl/certs/
chown root:root /etc/ssl/certs/srvwebcert.pem
```

## 5. Configuration du serveur web

### 5.1 Apache2
- Installation et activation du module SSL
![Modules SSL et Headers activÃ©s](images_resized/apache_enable_ssl_headers.png)
```bash
apt install -y apache2
a2enmod ssl headers
```
- CrÃ©ation/Ã©dition du vhost TLS `/etc/apache2/sites-available/default-ssl.conf`
![VHost SSL Apache Ã©ditÃ©](images_resized/apache_vhost_ssl_edit.png)
```apache
<IfModule mod_ssl.c>
  <VirtualHost *:443>
    ServerName www.exemple.local

    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile    /etc/ssl/certs/srvwebcert.pem
    SSLCertificateKeyFile /etc/ssl/private/srvwebkey.pem
    # Si vous avez une chaÃ®ne/intermÃ©diaire, ajoutez-la ici
    # SSLCertificateChainFile /etc/ssl/certs/chain.pem

    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    ErrorLog ${APACHE_LOG_DIR}/ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/ssl_access.log combined
  </VirtualHost>
</IfModule>
```
- Activer le site et rediriger le HTTP vers HTTPS (optionnel)
![Site SSL activÃ© et redirection HTTPâ†’HTTPS](images_resized/apache_enable_site_redirect.png)
```bash
a2ensite default-ssl
printf "<VirtualHost *:80>\n  ServerName www.exemple.local\n  Redirect permanent / https://www.exemple.local/\n</VirtualHost>\n" > /etc/apache2/sites-available/000-default.conf
systemctl restart apache2
```

### 5.2 Nginx (alternative)
- Installation et configuration basique
![Configuration Nginx HTTPS](images_resized/nginx_https_config.png)
```bash
apt install -y nginx
cat > /etc/nginx/sites-available/default <<'EOF'
server {
  listen 443 ssl http2;
  server_name www.exemple.local;

  root /var/www/html;

  ssl_certificate     /etc/ssl/certs/srvwebcert.pem;
  ssl_certificate_key /etc/ssl/private/srvwebkey.pem;

  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
}

server {
  listen 80;
  server_name www.exemple.local;
  return 301 https://$host$request_uri;
}
EOF
nginx -t && systemctl reload nginx
```

## 6. DÃ©ploiement du certificat racine sur les clients

### 6.1 Linux (Debian/Ubuntu)
![Ajout de la CA au magasin Linux](images_resized/client_linux_add_ca.png)
```bash
cp /etc/ssl/sodecaf/certs/cacert.pem /usr/local/share/ca-certificates/sodecaf-ca.crt
update-ca-certificates
```

### 6.2 Windows
- Ouvrir `mmc.exe` > Fichier > Ajouter/Supprimer un composant logiciel enfichable > Certificats.
- Choisir Â« Ordinateur local Â» > OK.
- Dans Â« AutoritÃ©s de certification racines de confiance Â» > Certificats > Clic droit > Toutes les tÃ¢ches > Importer > sÃ©lectionner `cacert.pem` (format `.cer` si besoin) > Terminer.
![Import CA dans le magasin Windows](images_resized/client_windows_mmc_import_ca.png)

### 6.3 Firefox (si stockage propre)
- ParamÃ¨tres > Vie privÃ©e et sÃ©curitÃ© > Certificats > Voir les certificats > AutoritÃ©s > Importer `cacert.pem` > Cocher Â« Identifier des sites web Â».
![Import CA dans Firefox](images_resized/client_firefox_import_ca.png)

## 7. VÃ©rifications et tests
- VÃ©rification cÃ´tÃ© TLS
![Sortie openssl s_client](images_resized/test_openssl_s_client.png)
```bash
openssl s_client -connect www.exemple.local:443 -servername www.exemple.local -showcerts </dev/null | openssl x509 -noout -issuer -subject -enddate
```
- Test HTTP(S)
![RÃ©ponse HTTP(S) avec curl](images_resized/test_curl_https.png)
```bash
curl -I https://www.exemple.local --resolve www.exemple.local:443:172.16.0.10 --cacert /etc/ssl/sodecaf/certs/cacert.pem
```
- Navigateur: vÃ©rifier le cadenas, le CN/SAN (Subject Alternative Name) et la validitÃ©.
![Cadenas navigateur et dÃ©tails du certificat](images_resized/browser_lock_and_cert_details.png)

## 8. Maintenance (renouvellement / rÃ©vocation)

### 8.1 Renouveler un certificat serveur
![Renouvellement du certificat serveur](images_resized/renew_server_cert.png)
```bash
# Sur le serveur web: rÃ©gÃ©nÃ©rer la CSR si nÃ©cessaire
openssl req -new -key /etc/ssl/private/srvwebkey.pem -out /etc/ssl/certs/srvwebkey_dem.pem

# Sur la CA: signer
openssl ca -policy policy_anything -out /etc/ssl/sodecaf/certs/srvwebcert.pem -infiles /etc/ssl/sodecaf/srvwebkey_dem.pem

# DÃ©ployer sur le serveur web puis recharger le service
systemctl reload apache2 || systemctl reload nginx
```

### 8.2 RÃ©voquer un certificat
![RÃ©vocation et gÃ©nÃ©ration de CRL](images_resized/revoke_and_gen_crl.png)
```bash
# Sur la CA: rÃ©voquer et publier la CRL
openssl ca -revoke /etc/ssl/sodecaf/newcerts/NNNN.pem
openssl ca -gencrl -out /etc/ssl/sodecaf/crl/sodecaf.crl
```
- Distribuer la CRL aux services/clients qui la consomment. Configurer `SSLUseStapling`/OCSP si pertinent.

## 9. DÃ©pannage (erreurs courantes)
- Nom non correspondant: le CN/SAN ne correspond pas au FQDN. RegÃ©nÃ©rer la CSR avec les bons SAN.
- ChaÃ®ne incomplÃ¨te: ajouter lâ€™intermÃ©diaire dans la directive de chaÃ®ne (si utilisÃ©).
- Permissions clÃ©s: la clÃ© privÃ©e doit Ãªtre lisible par le service seulement (`chmod 400`, propriÃ©taire `root`).
- Mauvais chemins de fichiers: vÃ©rifier les chemins des directives `SSLCertificateFile`/`ssl_certificate_key`.
- Horloge systÃ¨me: corriger le dÃ©calage NTP si dates invalides.
- Service ne dÃ©marre pas: consulter les journaux (`journalctl -u apache2 -xe` ou `nginx -t`).

---

## Conventions et emplacement des images
- Dossier suggÃ©rÃ©: `images/` Ã  la racine du projet ou Ã  cÃ´tÃ© de `test.md`.
- Format recommandÃ©: `.png`.
- Nommage: descriptif, en minuscules, mots sÃ©parÃ©s par `_` (ex: `apache_vhost_ssl_edit.png`).
- Vous pouvez renommer/dÃ©placer les fichiers; adaptez le chemin dans les balises `![...](images/xxx.png)` au besoin.


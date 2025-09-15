# Mise en oeuvre de l'HTTPS sur un serveur web
# Utilisation d'une autorité de certification interne

## 1. Préparation de la machine CA
- Configuration IP : /etc/network/interfaces
<p align="center"><img src="images/ca_ip_config.png" alt="Capture configuration IP de la CA" width="520"></p>
```bash
allow-hotplug ens33
iface ens33 inet static
        address 172.16.0.20/24
        gateway 172.16.0.254
```
- Installation d'openssl
<p align="center"><img src="images/ca_openssl_install.png" alt="Installation d'OpenSSL sur la CA" width="520"></p>
```bash
apt update && sudo apt upgrade -y
apt install openssl
```
## 2. configuration d'openssl
- Editez le fichier /etc/ssl/openssl.cnf
<p align="center"><img src="images/ca_openssl_cnf_edit.png" alt="Édition de openssl.cnf sur la CA" width="520"></p>
```bash
dir = /etc/ssl/sodecaf
certificate = $dir/certs/cacert.pem
```
- Création des dossiers et fichiers nécessaires
<p align="center"><img src="images/ca_tree_init.png" alt="Arborescence CA initiale" width="520"></p>
```bash
mkdir /etc/ssl/sodecaf
cd /etc/ssl/sodecaf/
mkdir certs
mkdir private
mkdir newcerts
touch index.txt
echo "01" > serial
```
## 3. Génération du certificat de l'autorité de certification
- Création de la clé privée de l'autorité de certification
<p align="center"><img src="images/ca_key_gen.png" alt="Génération de la clé privée de la CA" width="520"></p>
```bash
openssl genrsa -des3 -out /etc/ssl/sodecaf/private/cakey.pem 4096
chmod 400 /etc/ssl/sodecaf/private/cakey.pem
```
- Création du certificat auto-signé de l'autorité de certification
<p align="center"><img src="images/ca_self_signed_created.png" alt="Certificat auto-signé CA généré" width="520"></p>
```bash
cd /etc/ssl/sodecaf/
openssl req -new -x509 -days 1825 -key private/cakey.pem -out certs/cacert.pem
```
## 4. Génération du certificat du serveur web
On travaille sur le serveur web1
- Editez le fichier /etc/ssl/openssl.cnf
<p align="center"><img src="images/srv_openssl_cnf_edit.png" alt="Édition de openssl.cnf sur le serveur web" width="520"></p>
```bash
dir = /etc/ssl
```
- Création de la clé privée du serveur web
<p align="center"><img src="images/srv_key_gen.png" alt="Création de la clé privée serveur" width="520"></p>
```bash
openssl genrsa -out /etc/ssl/private/srvwebkey.pem 4096
```
- Création du fichier de demande de certificat
<p align="center"><img src="images/srv_csr_create.png" alt="Création de la CSR serveur" width="520"></p>
```bash
openssl req -new -key private/srvwebkey.pem -out certs/srvwebkey_dem.pem
```
- Copie du fichier de demande de certificat sur la machine CA
<p align="center"><img src="images/srv_csr_scp_to_ca.png" alt="Transfert de la CSR vers la CA" width="520"></p>
```bash
scp srvwebkey_dem.pem etudiant@172.16.0.20:/home/etudiant/
```
On travaille sur le serveur CA
- Création du certificat
<p align="center"><img src="images/ca_sign_server_cert.png" alt="Signature du certificat serveur par la CA" width="520"></p>
```bash
openssl ca -policy policy_anything -out /etc/ssl/sodecaf/certs/srvwebcert.pem -infiles /home/etudiant/srvwebkey_dem.pem 
```
- Copie du certificat sur le serveur web
<p align="center"><img src="images/ca_cert_scp_back.png" alt="Retour du certificat signé vers le serveur" width="520"></p>
```bash
scp srvwebcert.pem etudiant@172.16.0.10:/home/etudiant
```
On travaille sur le serveur web srv-web1
- Déplacement et changement de propriétaire du certificat
<p align="center"><img src="images/srv_place_certs.png" alt="Placement des certificats côté serveur" width="520"></p>
```bash
mv /home/etudiant/srvwebcert.pem /etc/ssl/certs/
chown root:root /etc/ssl/certs/srvwebcert.pem
```

## 5. Configuration du serveur web

### 5.1 Apache2
- Installation et activation du module SSL
<p align="center"><img src="images/apache_enable_ssl_headers.png" alt="Modules SSL et Headers activés" width="520"></p>
```bash
apt install -y apache2
a2enmod ssl headers
```
- Création/édition du vhost TLS `/etc/apache2/sites-available/default-ssl.conf`
<p align="center"><img src="images/apache_vhost_ssl_edit.png" alt="VHost SSL Apache édité" width="520"></p>
```apache
<IfModule mod_ssl.c>
  <VirtualHost *:443>
    ServerName www.exemple.local

    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile    /etc/ssl/certs/srvwebcert.pem
    SSLCertificateKeyFile /etc/ssl/private/srvwebkey.pem
    # Si vous avez une chaîne/intermédiaire, ajoutez-la ici
    # SSLCertificateChainFile /etc/ssl/certs/chain.pem

    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    ErrorLog ${APACHE_LOG_DIR}/ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/ssl_access.log combined
  </VirtualHost>
</IfModule>
```
- Activer le site et rediriger le HTTP vers HTTPS (optionnel)
<p align="center"><img src="images/apache_enable_site_redirect.png" alt="Site SSL activé et redirection HTTP→HTTPS" width="520"></p>
```bash
a2ensite default-ssl
printf "<VirtualHost *:80>\n  ServerName www.exemple.local\n  Redirect permanent / https://www.exemple.local/\n</VirtualHost>\n" > /etc/apache2/sites-available/000-default.conf
systemctl restart apache2
```

### 5.2 Nginx (alternative)
- Installation et configuration basique
<p align="center"><img src="images/nginx_https_config.png" alt="Configuration Nginx HTTPS" width="520"></p>
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

## 6. Déploiement du certificat racine sur les clients

### 6.1 Linux (Debian/Ubuntu)
<p align="center"><img src="images/client_linux_add_ca.png" alt="Ajout de la CA au magasin Linux" width="520"></p>
```bash
cp /etc/ssl/sodecaf/certs/cacert.pem /usr/local/share/ca-certificates/sodecaf-ca.crt
update-ca-certificates
```

### 6.2 Windows
- Ouvrir `mmc.exe` > Fichier > Ajouter/Supprimer un composant logiciel enfichable > Certificats.
- Choisir « Ordinateur local » > OK.
- Dans « Autorités de certification racines de confiance » > Certificats > Clic droit > Toutes les tâches > Importer > sélectionner `cacert.pem` (format `.cer` si besoin) > Terminer.
<p align="center"><img src="images/client_windows_mmc_import_ca.png" alt="Import CA dans le magasin Windows" width="520"></p>

### 6.3 Firefox (si stockage propre)
- Paramètres > Vie privée et sécurité > Certificats > Voir les certificats > Autorités > Importer `cacert.pem` > Cocher « Identifier des sites web ».
<p align="center"><img src="images/client_firefox_import_ca.png" alt="Import CA dans Firefox" width="520"></p>

## 7. Vérifications et tests
- Vérification côté TLS
<p align="center"><img src="images/test_openssl_s_client.png" alt="Sortie openssl s_client" width="520"></p>
```bash
openssl s_client -connect www.exemple.local:443 -servername www.exemple.local -showcerts </dev/null | openssl x509 -noout -issuer -subject -enddate
```
- Test HTTP(S)
<p align="center"><img src="images/test_curl_https.png" alt="Réponse HTTP(S) avec curl" width="520"></p>
```bash
curl -I https://www.exemple.local --resolve www.exemple.local:443:172.16.0.10 --cacert /etc/ssl/sodecaf/certs/cacert.pem
```
- Navigateur: vérifier le cadenas, le CN/SAN (Subject Alternative Name) et la validité.
<p align="center"><img src="images/browser_lock_and_cert_details.png" alt="Cadenas navigateur et détails du certificat" width="520"></p>

## 8. Maintenance (renouvellement / révocation)

### 8.1 Renouveler un certificat serveur
<p align="center"><img src="images/renew_server_cert.png" alt="Renouvellement du certificat serveur" width="520"></p>
```bash
# Sur le serveur web: régénérer la CSR si nécessaire
openssl req -new -key /etc/ssl/private/srvwebkey.pem -out /etc/ssl/certs/srvwebkey_dem.pem

# Sur la CA: signer
openssl ca -policy policy_anything -out /etc/ssl/sodecaf/certs/srvwebcert.pem -infiles /etc/ssl/sodecaf/srvwebkey_dem.pem

# Déployer sur le serveur web puis recharger le service
systemctl reload apache2 || systemctl reload nginx
```

### 8.2 Révoquer un certificat
<p align="center"><img src="images/revoke_and_gen_crl.png" alt="Révocation et génération de CRL" width="520"></p>
```bash
# Sur la CA: révoquer et publier la CRL
openssl ca -revoke /etc/ssl/sodecaf/newcerts/NNNN.pem
openssl ca -gencrl -out /etc/ssl/sodecaf/crl/sodecaf.crl
```
- Distribuer la CRL aux services/clients qui la consomment. Configurer `SSLUseStapling`/OCSP si pertinent.

## 9. Dépannage (erreurs courantes)
- Nom non correspondant: le CN/SAN ne correspond pas au FQDN. Regénérer la CSR avec les bons SAN.
- Chaîne incomplète: ajouter l’intermédiaire dans la directive de chaîne (si utilisé).
- Permissions clés: la clé privée doit être lisible par le service seulement (`chmod 400`, propriétaire `root`).
- Mauvais chemins de fichiers: vérifier les chemins des directives `SSLCertificateFile`/`ssl_certificate_key`.
- Horloge système: corriger le décalage NTP si dates invalides.
- Service ne démarre pas: consulter les journaux (`journalctl -u apache2 -xe` ou `nginx -t`).

---

## Conventions et emplacement des images
- Dossier suggéré: `images/` à la racine du projet ou à côté de `test.md`.
- Format recommandé: `.png`.
- Nommage: descriptif, en minuscules, mots séparés par `_` (ex: `apache_vhost_ssl_edit.png`).
- Vous pouvez renommer/déplacer les fichiers; adaptez le chemin dans les balises `![...](images/xxx.png)` au besoin.

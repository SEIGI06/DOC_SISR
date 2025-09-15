# Assets d'images pour la documentation HTTPS

Déposez vos captures dans le dossier `images/` (à côté de `test.md`).

## Liste des images attendues

- [ ] images/ca_ip_config.png — Configuration IP de la CA
- [ ] images/ca_openssl_install.png — Installation d'OpenSSL sur la CA
- [ ] images/ca_openssl_cnf_edit.png — Édition de `openssl.cnf` sur la CA
- [ ] images/ca_tree_init.png — Arborescence CA initiale
- [ ] images/ca_key_gen.png — Génération de la clé privée de la CA
- [ ] images/ca_self_signed_created.png — Certificat auto-signé CA généré
- [ ] images/srv_openssl_cnf_edit.png — Édition de `openssl.cnf` sur le serveur web
- [ ] images/srv_key_gen.png — Création de la clé privée serveur
- [ ] images/srv_csr_create.png — Création de la CSR serveur
- [ ] images/srv_csr_scp_to_ca.png — Transfert de la CSR vers la CA
- [ ] images/ca_sign_server_cert.png — Signature du certificat serveur par la CA
- [ ] images/ca_cert_scp_back.png — Retour du certificat signé vers le serveur
- [ ] images/srv_place_certs.png — Placement des certificats côté serveur
- [ ] images/apache_enable_ssl_headers.png — Activation SSL/Headers sur Apache
- [ ] images/apache_vhost_ssl_edit.png — VHost SSL Apache
- [ ] images/apache_enable_site_redirect.png — Activation du site SSL + redirection
- [ ] images/nginx_https_config.png — Configuration Nginx HTTPS
- [ ] images/client_linux_add_ca.png — Ajout de la CA au magasin Linux
- [ ] images/client_windows_mmc_import_ca.png — Import de la CA sous Windows (MMC)
- [ ] images/client_firefox_import_ca.png — Import de la CA dans Firefox
- [ ] images/test_openssl_s_client.png — Sortie `openssl s_client`
- [ ] images/test_curl_https.png — Test `curl` en HTTPS
- [ ] images/browser_lock_and_cert_details.png — Cadenas navigateur et détails du certificat
- [ ] images/renew_server_cert.png — Renouvellement du certificat serveur
- [ ] images/revoke_and_gen_crl.png — Révocation et génération de CRL

## Vérification rapide

1. Placez toutes les images ci-dessus dans `images/`.
2. Ouvrez `test.md` en aperçu Markdown (dans votre IDE ou GitHub).
3. Les balises doivent afficher les images sans erreur 404.

## Conseils

- Préférez `.png` pour des captures nettes.
- Conservez des noms courts et explicites.
- Si vous renommez un fichier, mettez à jour le chemin dans `test.md`.


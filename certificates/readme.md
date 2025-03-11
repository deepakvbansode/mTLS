# How to use generate_certs.sh script

1. Generate CA certificate
   `./generate_certs.sh ca`
2. Generate certficate signed by root ca
   `./generate_certs.sh client <server_name>`

## Note:

    Before generating certificate make sure CA is generated first. If CA is cert is not there then the script will generate the certificate but will not sign it.

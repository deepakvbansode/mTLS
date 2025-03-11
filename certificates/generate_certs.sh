#!/bin/bash

# Function to generate a CA certificate
generate_ca() {
    echo "Generating CA certificate and key..."
    mkdir -p ./certs/ca
    openssl req -x509 -newkey rsa:4096 -keyout ./certs/ca/ca_key.pem -out ./certs/ca/ca_crt.pem -days 365 -nodes -subj "/CN=CA"
    echo "CA certificate (ca_crt.pem) and key (ca_key.pem) generated."
}

# Function to generate a certificate signed by the CA
generate_certificate() {
    if [ -z "$1" ]; then
        echo "Error: Please provide a name for the certificate."
        exit 1
    fi

    NAME=$1
    mkdir -p "./certs/${NAME}"
    echo "Generating certificate and key for $NAME..."
    
    # Generate a private key
    openssl genpkey -algorithm RSA -out "./certs/${NAME}/${NAME}_key.pem"
    
    # Generate a certificate signing request (CSR)
    openssl req -new -key "./certs/${NAME}/${NAME}_key.pem" -out "./certs/${NAME}/${NAME}_csr.pem" -subj "/CN=${NAME}"
    
    # Sign the CSR with the CA certificate
    openssl x509 -req -in "./certs/${NAME}/${NAME}_csr.pem" -CA ./certs/ca/ca_crt.pem -CAkey ./certs/ca/ca_key.pem -CAcreateserial -out "./certs/${NAME}/${NAME}_crt.pem" -days 365
    
    echo "Certificate (${NAME}_crt.pem) and key (${NAME}_key.pem) generated and signed by CA."
}
generate_certificate() {
    if [ -z "$1" ]; then
        echo "Error: Please provide a name for the certificate."
        exit 1
    fi

    NAME=$1
    mkdir -p "./certs/${NAME}"
    echo "Generating certificate and key for $NAME..."

    # Create a configuration file for the certificate
    CONFIG_FILE="${NAME}.cnf"
    cat > "$CONFIG_FILE" <<EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
CN = ${NAME}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${NAME}
DNS.2 = localhost
EOF

    # Generate a private key
    openssl genpkey -algorithm RSA -out "./certs/${NAME}/${NAME}_key.pem"

    # Generate a certificate signing request (CSR)
    openssl req -new -key "./certs/${NAME}/${NAME}_key.pem" -out "./certs/${NAME}/${NAME}_csr.pem" -config "$CONFIG_FILE"

    # Sign the CSR with the CA certificate
    openssl x509 -req -in "./certs/${NAME}/${NAME}_csr.pem" -CA ./certs/ca/ca_crt.pem -CAkey ./certs/ca/ca_key.pem -CAcreateserial -out "./certs/${NAME}/${NAME}_crt.pem" -days 365 -extensions req_ext -extfile "$CONFIG_FILE"

    # Clean up the configuration file
    rm "$CONFIG_FILE"

    echo "Certificate (./certs/${NAME}/${NAME}.crt.pem) and key (./certs/${NAME}/${NAME}.key.pem) generated and signed by CA."
}

# Main script logic
if [ "$1" == "ca" ]; then
    generate_ca
elif [ "$1" == "client" ]; then
    generate_certificate "$2"
else
    echo "Usage:"
    echo "  ./generate_certs.sh ca                           # Generate CA certificate and key"
    echo "  ./generate_certs.sh certificate <name>           # Generate and sign a certificate for <name>"
    exit 1
fi
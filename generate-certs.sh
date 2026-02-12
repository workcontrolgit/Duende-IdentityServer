#!/bin/bash
# Generate self-signed SSL certificates for nginx-proxy

DOMAINS=("sts.skoruba.local" "admin.skoruba.local" "admin-api.skoruba.local")
CERT_DIR="shared/nginx/certs"

# Create certs directory if it doesn't exist
mkdir -p "$CERT_DIR"

for domain in "${DOMAINS[@]}"; do
    echo "Generating certificate for $domain..."

    # Generate private key
    openssl genrsa -out "$CERT_DIR/$domain.key" 2048

    # Generate certificate signing request
    openssl req -new -key "$CERT_DIR/$domain.key" \
        -out "$CERT_DIR/$domain.csr" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"

    # Generate self-signed certificate
    openssl x509 -req -days 365 \
        -in "$CERT_DIR/$domain.csr" \
        -signkey "$CERT_DIR/$domain.key" \
        -out "$CERT_DIR/$domain.crt"

    # Clean up CSR
    rm "$CERT_DIR/$domain.csr"

    echo "Created: $CERT_DIR/$domain.crt and $CERT_DIR/$domain.key"
    echo ""
done

echo "Certificate generation complete!"
echo "Restart Docker containers: docker-compose down && docker-compose up"

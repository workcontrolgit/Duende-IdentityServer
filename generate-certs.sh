#!/bin/bash
# Generate self-signed SSL certificates for nginx-proxy

DOMAINS=("sts.skoruba.local" "admin.skoruba.local" "admin-api.skoruba.local" "localhost")
CERT_DIR="shared/nginx/certs"

# Create certs directory if it doesn't exist
mkdir -p "$CERT_DIR"

for domain in "${DOMAINS[@]}"; do
    echo "Generating certificate for $domain..."

    # Generate self-signed certificate with SAN entries.
    # localhost cert includes 127.0.0.1 to avoid browser SAN validation failures.
    san="DNS:$domain"
    if [ "$domain" = "localhost" ]; then
        san="$san,IP:127.0.0.1"
    fi

    openssl req -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
        -keyout "$CERT_DIR/$domain.key" \
        -out "$CERT_DIR/$domain.crt" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain" \
        -addext "subjectAltName=$san"

    echo "Created: $CERT_DIR/$domain.crt and $CERT_DIR/$domain.key"
    echo ""
done

echo "Certificate generation complete!"
echo "Restart Docker containers: docker-compose down && docker-compose up"

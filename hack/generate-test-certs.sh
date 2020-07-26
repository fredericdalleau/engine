#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# integration/testdata/https (and integration-cli/fixtures/https, which has symlinks to these files)
OUT_DIR="${SCRIPT_DIR}/../integration/testdata/https"

# generate CA
echo 01 > "${OUT_DIR}/ca.srl"
openssl genrsa -out "${OUT_DIR}/ca-key.pem"

openssl req \
	-new \
	-x509 \
	-days 3652 \
	-subj "/C=US/ST=CA/L=SanFrancisco/O=Fort-Funston/OU=changeme/CN=changeme/name=changeme/emailAddress=mail@host.domain" \
	-nameopt compat \
	-text \
	-key "${OUT_DIR}/ca-key.pem" \
	-out "${OUT_DIR}/ca.pem"

# Now that we have a CA, create a server key and certificate signing request.
# Make sure that `"Common Name (e.g. server FQDN or YOUR name)"` matches the hostname you will use
# to connect or just use '*' for a certificate valid for any hostname:

openssl genrsa -out server-key.pem
openssl req -new \
	-subj "/C=US/ST=CA/L=SanFrancisco/O=Fort-Funston/OU=changeme/CN=*/name=changeme/emailAddress=mail@host.domain" \
	-text \
	-key "${OUT_DIR}/server-key.pem" \
	-out "${OUT_DIR}/server.csr"

# Options for server certificate
cat > "${OUT_DIR}/server-options.cfg" << 'EOF'
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
extendedKeyUsage=serverAuth
subjectAltName=DNS:*,DNS:localhost,IP:127.0.0.1,IP:::1
EOF

# Generate the certificate and sign with our CA
openssl x509 \
	-req \
	-days 3652 \
	-extfile "${OUT_DIR}/server-options.cfg" \
	-CA "${OUT_DIR}/ca.pem" \
	-CAkey "${OUT_DIR}/ca-key.pem" \
	-nameopt compat \
	-text \
	-in "${OUT_DIR}/server.csr" \
	-out "${OUT_DIR}/server-cert.pem"

# For client authentication, create a client key and certificate signing request
openssl genrsa -out "${OUT_DIR}/client-key.pem"
openssl req -new \
	-subj "/C=US/ST=CA/L=SanFrancisco/O=Fort-Funston/OU=changeme/CN=client/name=changeme/emailAddress=mail@host.domain" \
	-text \
	-key "${OUT_DIR}/client-key.pem" \
	-out "${OUT_DIR}/client.csr"

# Options for client certificate
cat > "${OUT_DIR}/client-options.cfg" << 'EOF'
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
extendedKeyUsage=clientAuth
subjectAltName=DNS:*,DNS:localhost,IP:127.0.0.1,IP:::1
EOF

# Generate the certificate and sign with our CA:
openssl x509 \
	-req \
	-days 3652 \
	-extfile "${OUT_DIR}/client-options.cfg" \
	-CA "${OUT_DIR}/ca.pem" \
	-CAkey "${OUT_DIR}/ca-key.pem" \
	-nameopt compat \
	-text \
	-in "${OUT_DIR}/client.csr" \
	-out "${OUT_DIR}/client-cert.pem"

rm "${OUT_DIR}/ca.srl"
rm "${OUT_DIR}/ca-key.pem"
rm "${OUT_DIR}"/*.cfg
rm "${OUT_DIR}"/*.csr

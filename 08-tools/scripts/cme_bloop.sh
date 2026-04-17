#!/bin/bash

# Usage:
# ./cme_bloop.sh <target> <username> <password> <protocol1,protocol2,...> [auth_type] [domain]
#
# auth_type:
#   domain -> use -d <DOMAIN>
#   local  -> use --local-auth
#   omitted -> no auth modifier added

TARGET=$1
USERNAME=$2
PASSWORD=$3
PROTO_LIST=$4
AUTH_TYPE=$5
DOMAIN=$6

if [ -z "$TARGET" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$PROTO_LIST" ]; then
    echo "Usage: $0 <target> <username> <password> <protocol1,protocol2,...> [auth_type] [domain]"
    echo "Example (domain): $0 192.168.111.137 alice 'Password123!' smb,winrm,rdp domain domain.com"
    echo "Example (local):  $0 192.168.111.137 administrator 'Password123!' smb,winrm local"
    echo "Example (basic):  $0 192.168.111.137 alice 'Password123!' smb,winrm"
    exit 1
fi

IFS=',' read -ra SERVICES <<< "$PROTO_LIST"

for SERVICE in "${SERVICES[@]}"
do
    echo -e "\n[*] Running CME against $SERVICE on $TARGET"

    CMD="crackmapexec $SERVICE $TARGET -u $USERNAME -p $PASSWORD"

    if [[ "$AUTH_TYPE" == "domain" && -n "$DOMAIN" && "$SERVICE" =~ ^(smb|ldap|winrm|mssql|rdp)$ ]]; then
        CMD+=" -d $DOMAIN"
    elif [[ "$AUTH_TYPE" == "local" && "$SERVICE" =~ ^(smb|winrm|rdp|mssql|ssh|ftp)$ ]]; then
        CMD+=" --local-auth"
    fi

    timeout 30s bash -c "$CMD" || echo "[!] $SERVICE check failed or timed out, continuing..."
done

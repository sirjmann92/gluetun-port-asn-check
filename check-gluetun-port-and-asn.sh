#!/bin/sh

# CONFIGURATION
GLUETUN_CONTAINER="yourGluetunContainerName"
ASN_FILE="/your/gluetun/composeOrConfig/directory/last_asn"
FORWARDED_PORT=yourVPNForwardedPortNumber
COMPOSE_DIR="/your/gluetun/compose/directory"
WEBHOOK_URL="https://discord.com/api/webhooks/yourDiscordChannelWebhookURL"

# Get current VPN IP from inside the container using wget
VPN_IP=$(docker exec "$GLUETUN_CONTAINER" wget -qO- https://ipinfo.io/ip)

# Verify that we got an IP
if [ -z "$VPN_IP" ]; then
    echo "$(date) - ERROR: Could not retrieve VPN IP from container $GLUETUN_CONTAINER." >&2
    exit 1
fi

# Check if port is open using nc, suppressing nc's own output
if nc -z -w3 "$VPN_IP" "$FORWARDED_PORT" >/dev/null 2>&1; then
    echo "$(date) - Port $FORWARDED_PORT on $VPN_IP is open and reachable."
else
    echo "$(date) - Port $FORWARDED_PORT on $VPN_IP is closed. Restarting stack..."
    cd "$COMPOSE_DIR"
    docker compose down
    sleep 5
    docker compose up -d

    # Notify via Webhook about the restart
    curl -X POST -H "Content-Type: application/json" \
        -d '{"content":"VPN port forwarding failed. Gluetun stack restarted to repair the issue."}' \
        "$WEBHOOK_URL"

    echo "$(date) - Stack restarted in $COMPOSE_DIR due to port $FORWARDED_PORT being closed."
fi

# Get current ASN (e.g., "AS213253 Private Layer INC")
CURRENT_ASN=$(docker exec "$GLUETUN_CONTAINER" wget -qO- https://ipinfo.io/org 2>/dev/null)
CURRENT_ASN_ID=$(echo "$CURRENT_ASN" | awk '{print $1}')

# Load previous ASN if it exists
if [ -f "$ASN_FILE" ]; then
    LAST_ASN_ID=$(cat "$ASN_FILE")
else
    LAST_ASN_ID=""
fi

# Always print the current ASN info
echo "$(date) - VPN ASN: $CURRENT_ASN_ID ($CURRENT_ASN)"

# Compare and act if ASN changed
if [ "$CURRENT_ASN_ID" != "$LAST_ASN_ID" ]; then
    echo "$CURRENT_ASN_ID" > "$ASN_FILE"

    # Notify via webhook if ASN changed
    curl -X POST -H "Content-Type: application/json" \
         -d "{\"content\":\"VPN ASN changed: $LAST_ASN_ID → $CURRENT_ASN_ID ($CURRENT_ASN)\"}" \
         "$WEBHOOK_URL" >/dev/null 2>&1

    echo "$(date) - ASN changed from $LAST_ASN_ID to $CURRENT_ASN_ID"
else
    echo "$(date) - ASN is unchanged: $LAST_ASN_ID → $CURRENT_ASN_ID"
fi

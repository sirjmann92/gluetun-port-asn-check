# Gluetun VPN Monitor & Auto-Recovery Script

If your VPN IP address/locale changes frequently while using the Docker gluetun container causing your forwarded port and VPN tunnel to collapse, you can try adding the below environment variable to the your gluetun container's environment variables.
```
HEALTH_VPN_DURATION_INITIAL=120s
```
If you're still having trouble with frequent IP changes breaking your forwarded port, or if you'd like to automate container restarts and be notified, this script monitors the health of a Gluetun-based VPN container by checking two key things:

- ✅ **Forwarded Port Accessibility**: Ensures your VPN provider's port forwarding remains open.
- 🔄 **ASN (Autonomous System Number) Consistency**: Detects changes in the provider network (useful for ASN-locked services like MyAnonamouse).

If either check fails:
- The stack is automatically restarted using Docker Compose.
- A Discord webhook notification is sent to alert you.

---

## 🔧 Configuration

Before using, update the configuration section at the top of the script:

```sh
GLUETUN_CONTAINER="yourGluetunContainerName"
ASN_FILE="/your/gluetun/composeOrConfig/directory/last_asn"
FORWARDED_PORT=yourVPNForwardedPortNumber
COMPOSE_DIR="/your/gluetun/compose/directory"
WEBHOOK_URL="https://discord.com/api/webhooks/yourDiscordChannelWebhookURL"
```

---

## 📋 Features

- 🕵️‍♂️ Verifies external VPN IP via `ipinfo.io`
- 🌐 Checks forwarded port with `nc`
- 🔁 Restarts the stack if the port is closed
- 🛰️ Tracks ASN to detect VPN provider or network changes
- 🔔 Sends Discord notifications for:
  - Port closure/restart event
  - ASN change event

---

## 🛠️ Requirements

- Docker & Docker Compose
- `wget`, `nc`, `curl` available inside the container and on the host
- Gluetun container configured with a forwarded port

---

## 🧪 Example Output

```
Sat Jul 26 19:23:01 2025 - Port 50000 on 185.XXX.XXX.XXX is open and reachable.
Sat Jul 26 19:23:01 2025 - VPN ASN: AS213253 (Private Layer INC)
Sat Jul 26 19:23:01 2025 - ASN is unchanged: AS213253 → AS213253
```

If the port is unreachable:

```
Sat Jul 26 19:23:01 2025 - Port 50000 on 185.XXX.XXX.XXX is closed. Restarting stack...
Sat Jul 26 19:23:12 2025 - Stack restarted in /docker/gluetun due to port 50000 being closed.
```

If the ASN changes:

```
Sat Jul 26 19:24:01 2025 - ASN changed from AS213253 to AS208722
```

---

## 🧭 Usage

Schedule it with `cron` or your preferred scheduler:

```sh
*/10 * * * * /path/to/gluetun-monitor.sh >> /var/log/gluetun-monitor.log 2>&1
```

---

## 🧑‍💻 Author & License

- Created by sirjmann92
- MIT License

---

## 📌 Tip

Pair this script with Gluetun's [port forwarding setup](https://github.com/qdm12/gluetun/wiki/Port-forwarding) to maintain reliability in torrenting or services that require consistent open ports.

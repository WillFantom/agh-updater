# AdGuard Home + Træfik

Always ensure your AdGuard Home TLS settings are in sync with your Træfik generated certs!

---

If you use [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) for DoH/DoQ/DoT, and you use Træfik Proxy + Lets Encrypt to automatically generate certs for your AdGuard domain, you will know that it can be annoying when your certs expire and you have to go diving in your Træfik certs file to find and decode your cert and key for AdGuard... It's a whole 2-minute task every few months!! If you just can't deal with that pain, this is for you 🫵

## Usage [with docker 🐳]

Simply run the container with your credentials and paths set up:

```bash
docker run --rm -d --name agh-updater -v /services/traefik/certs:/traefikcerts:ro \
  -e ADGUARD_USERNAME=exampleuser -e ADGUARD_PASSWORD=asecret \
  -e ADGUARD_DOMAIN=adguard.example.com -e TRAEFIK_CERT_JSON=/traefikcerts/acme.json \
  ghcr.io/willfantom/agh-updater:latest
```

## Usage [with docker compose 🐳]

See the example setup [here](/example/docker-compose.yml)!

## Usage [bash]

```bash
  ./agh-updater.sh -u exampleuser -p asecret \
    -d adguard.example.com -f /services/traefik/certs/acme.json
```

## Configuration

|       ENV Variable       | CLI Parameter |                       Description                        |      Default       | Required |
| :----------------------: | :-----------: | :------------------------------------------------------: | :----------------: | :------: |
|    `ADGUARD_USERNAME`    |    `-u <>`    |     Your AdGuard Home admin username for API access      |        N/A         |    ✅     |
|    `ADGUARD_PASSWORD`    |    `-p <>`    |     Your AdGuard Home admin password for API access      |        N/A         |    ✅     |
|     `ADGUARD_DOMAIN`     |    `-d <>`    |    Your AdGuard Home domain (without scheme or port)     |        N/A         |    ✅     |
|   `TRAEFIK_CERT_JSON`    |    `-f <>`    |          Path to your Træfik cert storage file           |        N/A         |    ✅     |
| `INTERVAL` (Docker only) |    `-i <>`    | ReUpdate the certs every X seconds (`0` if do only once) | 0 (`60` in Docker) |    ❌     |
|                          |     `-e`      |       Exit update loop if an error is encountered        |      not-set       |    ❌     |
|   `ADGUARD_API_SCHEME`   |               |    Scheme to use to access your AdGuard instance API     |      `https`       |    ❌     |
|    `ADGUARD_API_PORT`    |               |         Port to access your AdGuard instance API         |       `443`        |    ❌     |
|                          |     `-h`      |                      Print CLI Help                      |                    |    ❌     |
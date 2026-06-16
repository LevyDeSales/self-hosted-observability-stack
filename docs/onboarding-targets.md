# Onboarding de Novos Targets

Use este fluxo sempre que adicionar uma nova VPS, app ou conjunto de containers
criticos.

## Checklist

- [ ] Modelo de exposicao escolhido em [exposure-model.md](exposure-model.md)
  antes de abrir portas ou configurar Beszel Agent/firewall.
- [ ] O host tem IP privado ou VPN ate o host central.
- [ ] Se nao houver private network comum, Tailscale foi instalado no host central e no host remoto.
- [ ] O Beszel Agent escuta somente em IP privado.
- [ ] O firewall permite `45876/tcp` somente do host central.
- [ ] O sistema foi cadastrado no Beszel.
- [ ] Alertas CPU, memoria, disco e status foram criados.
- [ ] O endpoint publico foi cadastrado no Uptime Kuma.
- [ ] TLS expiry foi habilitado no monitor HTTP.
- [ ] Containers criticos tem push monitor.
- [ ] Backup tem push monitor quando houver dados persistentes.
- [ ] Inventario foi atualizado.

## Nomeacao

| Recurso | Padrao | Exemplo |
| --- | --- | --- |
| Host | `vps-<app>` | `vps-api` |
| Beszel system | mesmo nome do host | `vps-api` |
| Agent container | `observability-beszel-agent-<app>` | `observability-beszel-agent-api` |
| Uptime HTTP | FQDN | `api.example.com` |
| Uptime containers | `<app>-containers` | `api-containers` |
| Uptime backup | `<app>-backup-s3` | `api-backup-s3` |
| Service | `observability-containers.service` | um por host ou customizado por app |
| Timer | `observability-containers.timer` | um por host ou customizado por app |

## Beszel Agent

No host remoto:

```bash
install -d -m 0700 /etc/observability-stack
install -m 0600 /dev/null /etc/observability-stack/remote-agent.env
mkdir -p /opt/observability/beszel-agent
```

Env minimo:

```text
HOST_SLUG="api"
BESZEL_AGENT_KEY="<public-key-do-hub>"
BESZEL_AGENT_LISTEN="10.0.0.2:45876"
```

Se o host remoto nao estiver na mesma private network do host central, instale
Tailscale nos dois hosts e use o IP Tailscale:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
tailscale ip -4
```

Exemplo com Tailscale:

```text
BESZEL_AGENT_LISTEN="100.x.y.20:45876"
```

Subir:

```bash
docker compose --env-file /etc/observability-stack/remote-agent.env \
  -f "$REPO_DIR/examples/docker-compose/beszel-agent.remote.yml" \
  -p observability-beszel-agent up -d
```

Firewall:

Antes de aplicar, remova regras antigas amplas/publicas para `45876/tcp`.

```bash
ufw allow proto tcp from 10.0.0.1 to any port 45876 \
  comment "beszel agent from central host"
ufw deny 45876/tcp
```

Firewall com Tailscale:

Antes de aplicar, remova regras antigas amplas/publicas para `45876/tcp`.

```bash
ufw allow in on tailscale0 to any port 45876 proto tcp \
  comment "beszel agent over tailscale"
ufw deny 45876/tcp
```

Aceite:

```bash
ssh <central-host> 'nc -vz 10.0.0.2 45876'
ssh <central-host> 'nc -vz <remote-tailscale-ip> 45876'
nc -vz <public-ip> 45876
```

Os checks por IP privado e por Tailscale devem funcionar quando esses caminhos
forem usados. O check por IP publico deve falhar.

## Uptime HTTP/TLS

Crie um monitor HTTP(s):

| Campo | Valor |
| --- | --- |
| Friendly Name | FQDN do app |
| URL | `https://<fqdn>` |
| Heartbeat Interval | `60` |
| Retries | `3` |
| Accepted Status Codes | `200-299` |
| TLS Expiry Notification | ligado |

Valide:

```bash
curl -sk -o /dev/null -w '%{http_code}\n' https://<fqdn>
```

## Uptime Push para containers

Crie um monitor Push:

```text
name = <app>-containers
interval = 60s
```

No host alvo, configure:

```text
UPTIME_KUMA_PUSH_URL="https://monitor.example.com/api/push/<token>"
REQUIRED_CONTAINERS="app-web-1 app-worker-1 app-postgres-1 app-redis-1"
HEALTHCHECK_CONTAINERS="app-postgres-1 app-redis-1"
```

Instale o service/timer conforme [installation.md](installation.md).

## Uptime Push para backup

Crie um monitor Push:

```text
name = <app>-backup-s3
interval = 3600s
```

No host que consegue ler o backup:

```text
UPTIME_KUMA_PUSH_URL="https://monitor.example.com/api/push/<token>"
RCLONE_REMOTE_PATH="s3remote:bucket/path/to/backups"
MAX_AGE_HOURS="26"
MIN_SIZE_BYTES="1"
```

Aceite:

- O service manual retorna `0`.
- O Uptime Kuma mostra UP.
- O backup real existe fora da VPS.

## Registro

Copie [templates/monitoring-target.md](templates/monitoring-target.md) para seu
inventario e preencha tudo que foi criado.

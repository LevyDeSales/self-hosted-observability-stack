# Instalacao

Este guia assume Ubuntu/Debian, Docker Compose e um reverse proxy gerenciado
pelo Dokploy ou equivalente. Adapte comandos de pacote se usar outra distro.

## 1. Inventario

Preencha uma copia de [templates/host-inventory.md](templates/host-inventory.md)
antes de instalar.

Valores minimos:

| Chave | Exemplo |
| --- | --- |
| `MONITOR_FQDN` | `monitor.example.com` |
| `METRICS_FQDN` | `metrics.example.com` |
| `CENTRAL_HOST` | `vps-panel` |
| `CENTRAL_PRIVATE_IP` | `10.0.0.1` |
| `PRIVATE_CIDR` | `10.0.0.0/24` |
| `REMOTE_HOSTS` | `vps-app=10.0.0.2` |

## 2. Modelo de exposicao

Antes de instalar servicos ou abrir portas, escolha o modelo em
[exposure-model.md](exposure-model.md).

Registre no inventario qual cenario se aplica:

| Topologia | Padrao |
| --- | --- |
| Homelab sem IP publico | Cloudflare Access + Cloudflare Tunnel. |
| VPS com IP publico | Access sem Tunnel, DNS proxied e firewall de origem. |
| VPS com rede privada do provedor | Reverse proxy publico + trafego interno por private IP. |
| VPSs sem rede privada comum | Access para paineis + Tailscale para metricas internas. |
| Hibrido | Entrada publica, private IP onde existir e Tailscale para cross-provider/admin. |

Nao avance para DNS, firewall ou deploy enquanto o modelo de exposicao nao
estiver definido.

## 3. Pre-requisitos no host central

```bash
apt-get update
apt-get install -y docker.io docker-compose-plugin ufw netcat-openbsd curl git rclone
docker compose version
```

Se usar Dokploy, valide que a rede externa existe:

```bash
docker network inspect dokploy-network >/dev/null
```

Se nao usar Dokploy, remova `dokploy-network` dos exemplos ou substitua pelo
nome da rede do seu reverse proxy.

## 4. Obter este repo nos hosts

Em cada host que receber arquivos deste repo, clone ou atualize uma copia local:

```bash
REPO_DIR=/opt/observability-stack-src
if [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" pull --ff-only
else
  git clone https://github.com/LevyDeSales/self-hosted-observability-stack.git \
    "$REPO_DIR"
fi
cd "$REPO_DIR"
```

Se voce publicou um fork, substitua a URL pelo fork.

## 5. Rede privada ou Tailscale

O Beszel Hub precisa conectar em cada Beszel Agent por TCP. Use uma destas
opcoes:

| Cenario | Padrao |
| --- | --- |
| VPSs no mesmo provedor e mesma private network | Use os private IPs do provedor. |
| VPSs em provedores diferentes ou sem private network comum | Instale Tailscale nos hosts de observabilidade. |
| Sem VPN nem private network | Nao publique `45876/tcp`; use apenas Uptime Kuma push ate configurar Tailscale ou outra VPN. |

Para Tailscale, instale no host central e em cada host remoto:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
tailscale status
tailscale ip -4
```

Para instalacao automatizada, gere uma auth key no Tailscale e passe pelo
ambiente do host, sem gravar no Git:

```bash
export TAILSCALE_AUTH_KEY="<tskey-auth-...>"
tailscale up --auth-key "$TAILSCALE_AUTH_KEY" --hostname "$(hostname -s)"
```

Anote os IPs Tailscale:

```text
central_tailscale_ip = 100.x.y.10
remote_tailscale_ip  = 100.x.y.20
```

Quando usar Tailscale, substitua os private IPs dos exemplos pelo IP Tailscale.
No host remoto, o Beszel Agent deve escutar no IP Tailscale:

```text
BESZEL_AGENT_LISTEN="100.x.y.20:45876"
```

No firewall do host remoto, permita o agent somente pela interface Tailscale:

```bash
ufw allow in on tailscale0 to any port 45876 proto tcp \
  comment "beszel agent over tailscale"
ufw deny 45876/tcp
```

Valide a partir do host central:

```bash
nc -vz 100.x.y.20 45876
nc -vz <remote-public-ip> 45876
```

O primeiro comando deve funcionar. O segundo deve falhar.

## 6. DNS e borda

Crie dois FQDNs:

```text
monitor.example.com -> host central
metrics.example.com -> host central
```

Proteja ambos com Cloudflare Access, VPN, SSO no reverse proxy ou outro
mecanismo equivalente.

Se seus checks por push vierem de hosts externos e voce usar Cloudflare Access,
crie uma excecao apenas para:

```text
https://monitor.example.com/api/push/*
```

Essa excecao deve existir somente porque a URL de push ja contem token. Se voce
puder rotear push por rede privada, prefira rede privada.

## 7. Segredos no host

Crie arquivos remotos com permissao restrita:

```bash
install -d -m 0700 /etc/observability-stack
install -m 0600 /dev/null /etc/observability-stack/central.env
install -m 0600 /dev/null /etc/observability-stack/containers.env
install -m 0600 /dev/null /etc/observability-stack/backup.env
```

Use [examples/env/central.env.example](../examples/env/central.env.example) como
base. Nao copie valores reais para o Git.

## 8. Deploy Uptime Kuma

No host central:

```bash
mkdir -p /opt/observability/uptime-kuma
cp "$REPO_DIR/examples/docker-compose/uptime-kuma.dokploy.yml" \
  /opt/observability/uptime-kuma/docker-compose.yml
cd /opt/observability/uptime-kuma
docker compose --env-file /etc/observability-stack/central.env \
  -p observability-uptime-kuma up -d
```

Valide:

```bash
docker ps --filter name=observability-uptime-kuma \
  --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

Depois acesse `https://monitor.example.com`, crie o admin e configure pelo
menos um canal de notificacao.

## 9. Deploy Beszel Hub e agent local

No host central:

```bash
mkdir -p /opt/observability/beszel
cp "$REPO_DIR/examples/docker-compose/beszel-hub-agent.dokploy.yml" \
  /opt/observability/beszel/docker-compose.yml
cd /opt/observability/beszel
docker compose --env-file /etc/observability-stack/central.env \
  -p observability-beszel up -d
```

Valide:

```bash
docker ps --filter name=observability-beszel \
  --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
nc -vz <central-private-ip> 45876
```

Se o Hub roda em container e o Agent local usa `network_mode: host`, libere o
bridge Docker do compose para falar com `45876/tcp`:

```bash
ufw allow proto tcp from 172.16.0.0/12 to any port 45876 \
  comment "beszel hub docker bridge to local agent"
```

Ajuste a origem para o CIDR real da rede Docker se voce preferir ser mais
restritivo.

## 10. Deploy Beszel Agent remoto

Em cada host remoto, crie env e compose:

```bash
install -d -m 0700 /etc/observability-stack
install -m 0600 /dev/null /etc/observability-stack/remote-agent.env
mkdir -p /opt/observability/beszel-agent
cp "$REPO_DIR/examples/docker-compose/beszel-agent.remote.yml" \
  /opt/observability/beszel-agent/docker-compose.yml
```

Preencha `/etc/observability-stack/remote-agent.env` com base em
[examples/env/remote-agent.env.example](../examples/env/remote-agent.env.example).
Se estiver usando Tailscale, use o IP Tailscale do host remoto em
`BESZEL_AGENT_LISTEN`.

Suba:

```bash
cd /opt/observability/beszel-agent
docker compose --env-file /etc/observability-stack/remote-agent.env \
  -p observability-beszel-agent up -d
```

Firewall no host remoto com private network do provedor:

Antes de aplicar, remova regras antigas amplas/publicas para `45876/tcp`.

```bash
ufw allow proto tcp from 10.0.0.1 to any port 45876 \
  comment "beszel agent from central host"
ufw deny 45876/tcp
ufw status numbered
```

Firewall no host remoto com Tailscale:

Antes de aplicar, remova regras antigas amplas/publicas para `45876/tcp`.

```bash
ufw allow in on tailscale0 to any port 45876 proto tcp \
  comment "beszel agent over tailscale"
ufw deny 45876/tcp
ufw status numbered
```

Valide a partir do host central:

```bash
nc -vz 10.0.0.2 45876
```

Valide de fora que o IP publico nao conecta:

```bash
nc -vz <public-ip-remoto> 45876
```

O teste publico deve falhar.

## 11. Configurar Beszel

No painel `https://metrics.example.com`:

1. Crie o admin.
2. Adicione o host central com IP privado/Tailscale e porta `45876`.
3. Adicione cada host remoto com IP privado/Tailscale e porta `45876`.
4. Confirme que Docker stats aparecem.
5. Crie alertas iniciais:

| Alerta | Valor | Janela |
| --- | --- | --- |
| Status | Down | imediato |
| CPU | `90%` | `5 min` |
| Memoria | `85%` | `5 min` |
| Disco | `80%` | `5 min` |

## 12. Configurar Uptime Kuma

No painel `https://monitor.example.com`, crie:

| Monitor | Tipo | Configuracao |
| --- | --- | --- |
| App publico | HTTP(s) | URL, `200-299`, intervalo `60s`, retries `3`, TLS expiry ligado |
| Containers | Push | Nome `<app>-containers`, intervalo `60s` |
| Backup | Push | Nome `<app>-backup-s3`, intervalo `3600s` |

Guarde as push URLs em arquivos `0600` no host alvo.

## 13. Instalar timer de containers

No host onde os containers do app rodam:

```bash
install -d -m 0700 /etc/observability-stack
install -m 0600 "$REPO_DIR/examples/env/containers.env.example" \
  /etc/observability-stack/containers.env
```

Edite `/etc/observability-stack/containers.env` com a push URL real e os
containers criticos antes de instalar e habilitar o timer.

```bash
install -m 0755 "$REPO_DIR/scripts/check-containers.sh" \
  /usr/local/sbin/check-containers.sh
install -m 0644 "$REPO_DIR/systemd/observability-containers.service" \
  /etc/systemd/system/observability-containers.service
install -m 0644 "$REPO_DIR/systemd/observability-containers.timer" \
  /etc/systemd/system/observability-containers.timer
systemctl daemon-reload
```

Valide manualmente antes de habilitar:

```bash
systemctl start observability-containers.service
journalctl -u observability-containers.service -n 100 --no-pager
```

Se o teste manual reportar UP no Uptime Kuma, habilite:

```bash
systemctl enable --now observability-containers.timer
```

## 14. Instalar timer de backup

No host que consegue ler o destino de backup:

```bash
install -m 0600 "$REPO_DIR/examples/env/backup.env.example" \
  /etc/observability-stack/backup.env
```

Edite `/etc/observability-stack/backup.env` com a push URL e o remote path real.

```bash
install -m 0755 "$REPO_DIR/scripts/check-s3-backup-rclone.sh" \
  /usr/local/sbin/check-s3-backup-rclone.sh
install -m 0644 "$REPO_DIR/systemd/observability-s3-backup.service" \
  /etc/systemd/system/observability-s3-backup.service
install -m 0644 "$REPO_DIR/systemd/observability-s3-backup.timer" \
  /etc/systemd/system/observability-s3-backup.timer
systemctl daemon-reload
```

Valide manualmente antes de habilitar:

```bash
systemctl start observability-s3-backup.service
journalctl -u observability-s3-backup.service -n 100 --no-pager
```

Se o teste manual reportar UP no Uptime Kuma, habilite:

```bash
systemctl enable --now observability-s3-backup.timer
```

## 15. Aceite

Antes de declarar a instalacao concluida:

```bash
# Paineis: devem exigir Access, VPN, SSO ou gate equivalente.
curl -skI https://monitor.example.com
curl -skI https://metrics.example.com

# Push: so deve bypassar login interativo se o bypass foi criado de proposito.
curl -skI https://monitor.example.com/api/push/test

# Origem publica: nao deve servir paineis direto pelo IP publico.
curl -skI https://<public-vps-ip>
curl -skI --resolve monitor.example.com:443:<public-vps-ip> \
  https://monitor.example.com
curl -skI --resolve metrics.example.com:443:<public-vps-ip> \
  https://metrics.example.com

# Metricas internas: devem funcionar apenas pelo caminho privado escolhido.
nc -vz <remote-private-or-tailscale-ip> 45876
nc -vz <remote-public-ip> 45876

systemctl list-timers | grep observability
```

Resultado esperado:

- Uptime Kuma e Beszel nao ficam anonimamente utilizaveis pelo dominio publico:
  o acesso sem sessao deve cair em challenge/redirect/401 do Cloudflare Access,
  recusa de VPN, ou gate de SSO equivalente.
- Se push externo usa bypass, apenas `/api/push/*` responde sem login
  interativo; outros paths de `monitor.example.com` continuam protegidos.
- Se push bypass nao foi habilitado, `/api/push/*` tambem deve exigir o mesmo
  gate dos demais paths.
- Requisicoes diretas para `<public-vps-ip>` nao servem Uptime Kuma, Beszel Hub
  nem outro painel administrativo.
- Requisicoes diretas para a origem com `--resolve` falham por firewall, por
  autenticacao de origem, ou nao servem paineis fora do caminho esperado.
- Beszel ve todos os hosts.
- Porta `45876` funciona por IP privado/Tailscale e falha por IP publico.
- Uptime Kuma mostra HTTP/TLS, containers e backup como UP.
- Nenhum segredo foi gravado no repositorio.

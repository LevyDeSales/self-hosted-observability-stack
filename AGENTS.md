# Agent Handoff

Estas instrucoes sao para agentes de IA ou operadores que receberam este repo
com a missao de instalar a stack em hosts de outra pessoa.

## Objetivo

Instalar uma stack de observabilidade self-hosted com:

- Uptime Kuma para HTTP/TLS e push heartbeats.
- Beszel Hub no host central.
- Beszel Agent no host central e nos hosts remotos.
- systemd timers para checks de containers e backups.
- Cloudflare Access ou mecanismo equivalente para proteger paineis.

## Nao fazer

- Nao commitar `.env`, tokens, senhas, chaves SSH, URLs de push reais ou
  endpoints privados sensiveis.
- Nao abrir `45876/tcp` do Beszel Agent para `0.0.0.0/0`.
- Nao abrir portas nem configurar Access, Tunnel ou Tailscale antes de ler
  [docs/exposure-model.md](docs/exposure-model.md) e classificar a topologia.
- Nao marcar backup como monitorado antes de validar um backup real fora da VPS.
- Nao remover firewall ou Access para "testar rapido" sem recolocar a protecao.
- Nao substituir o inventario real por nomes de exemplo do repo.

## Perguntas minimas para o dono da infra

Antes de instalar, obtenha:

| Pergunta | Exemplo |
| --- | --- |
| Dominio do Uptime Kuma | `monitor.example.com` |
| Dominio do Beszel | `metrics.example.com` |
| Host central | `vps-panel` |
| IP privado do host central | `10.0.0.1` |
| Hosts remotos e IPs privados | `vps-app = 10.0.0.2` |
| Hosts no mesmo provedor/private network? | se nao, usar Tailscale |
| Modelo de exposicao | Access sem Tunnel, Access + Tunnel, private network, Tailscale ou hibrido |
| Provedor DNS/borda | Cloudflare, Nginx, Traefik, Caddy |
| SMTP de alertas | host, porta, usuario, remetente |
| Apps publicos a monitorar | FQDN, status esperado, intervalo |
| Containers criticos por app | nomes exatos de containers Docker |
| Destino de backup | rclone remote path ou runbook de backup |

## Ordem de execucao

1. Preencher [docs/templates/host-inventory.md](docs/templates/host-inventory.md).
2. Ler [docs/exposure-model.md](docs/exposure-model.md) e escolher o modelo
   antes de abrir portas ou configurar Access/Tunnel/Tailscale.
3. Validar pre-requisitos em [docs/installation.md](docs/installation.md).
4. Clonar ou atualizar este repo nos hosts que receberao arquivos.
5. Confirmar private network comum; se nao existir, instalar Tailscale.
6. Configurar DNS e protecao de borda.
7. Subir Uptime Kuma com [examples/docker-compose/uptime-kuma.dokploy.yml](examples/docker-compose/uptime-kuma.dokploy.yml).
8. Subir Beszel Hub + Agent local com [examples/docker-compose/beszel-hub-agent.dokploy.yml](examples/docker-compose/beszel-hub-agent.dokploy.yml).
9. Subir um Beszel Agent por host remoto com [examples/docker-compose/beszel-agent.remote.yml](examples/docker-compose/beszel-agent.remote.yml).
10. Criar monitores HTTP/TLS e push no Uptime Kuma.
11. Instalar scripts e timers em [scripts](scripts) e [systemd](systemd).
12. Criar sistemas e alertas no Beszel.
13. Rodar a secao de aceite de [docs/installation.md](docs/installation.md).

## Padrao de resposta ao finalizar

Informe ao dono da infra:

- URL dos paineis.
- Hosts cadastrados no Beszel.
- Monitores criados no Uptime Kuma.
- Timers systemd instalados.
- Checks que passaram.
- Pendencias explicitas, se houver.

Nao inclua senhas ou tokens na resposta.

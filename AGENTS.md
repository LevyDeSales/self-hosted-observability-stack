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
| Provedor DNS/borda | Cloudflare, Nginx, Traefik, Caddy |
| SMTP de alertas | host, porta, usuario, remetente |
| Apps publicos a monitorar | FQDN, status esperado, intervalo |
| Containers criticos por app | nomes exatos de containers Docker |
| Destino de backup | rclone remote path ou runbook de backup |

## Ordem de execucao

1. Preencher [docs/templates/host-inventory.md](docs/templates/host-inventory.md).
2. Validar pre-requisitos em [docs/installation.md](docs/installation.md).
3. Clonar ou atualizar este repo nos hosts que receberao arquivos.
4. Confirmar private network comum; se nao existir, instalar Tailscale.
5. Configurar DNS e protecao de borda.
6. Subir Uptime Kuma com [examples/docker-compose/uptime-kuma.dokploy.yml](examples/docker-compose/uptime-kuma.dokploy.yml).
7. Subir Beszel Hub + Agent local com [examples/docker-compose/beszel-hub-agent.dokploy.yml](examples/docker-compose/beszel-hub-agent.dokploy.yml).
8. Subir um Beszel Agent por host remoto com [examples/docker-compose/beszel-agent.remote.yml](examples/docker-compose/beszel-agent.remote.yml).
9. Criar monitores HTTP/TLS e push no Uptime Kuma.
10. Instalar scripts e timers em [scripts](scripts) e [systemd](systemd).
11. Criar sistemas e alertas no Beszel.
12. Rodar a secao de aceite de [docs/installation.md](docs/installation.md).

## Padrao de resposta ao finalizar

Informe ao dono da infra:

- URL dos paineis.
- Hosts cadastrados no Beszel.
- Monitores criados no Uptime Kuma.
- Timers systemd instalados.
- Checks que passaram.
- Pendencias explicitas, se houver.

Nao inclua senhas ou tokens na resposta.

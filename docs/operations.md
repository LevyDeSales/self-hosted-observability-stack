# Operacao

Use este documento para validar a stack, investigar alertas e orientar
manutencao.

## Status rapido

No host central:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" |
  grep -E "observability|uptime|beszel"
systemctl list-timers | grep observability || true
curl -skI https://monitor.example.com | sed -n '1,8p'
curl -skI https://metrics.example.com | sed -n '1,8p'
```

Em cada host remoto:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" |
  grep beszel
systemctl list-timers | grep observability || true
```

## Logs

```bash
docker logs --tail=200 observability-uptime-kuma
docker logs --tail=200 observability-beszel-hub
docker logs --tail=200 observability-beszel-agent-local
docker logs --tail=200 observability-beszel-agent-<host-slug>
journalctl -u observability-containers.service -n 100 --no-pager
journalctl -u observability-s3-backup.service -n 100 --no-pager
```

## Uptime Kuma

Monitores esperados por app:

| Monitor | Tipo | OK quando |
| --- | --- | --- |
| FQDN publico | HTTP(s) | status esperado e TLS valido |
| `<app>-containers` | Push | containers criticos rodam e healthchecks passam |
| `<app>-backup-s3` | Push | backup recente e nao vazio existe fora da VPS |

Validar push manualmente:

```bash
/usr/local/sbin/check-containers.sh /etc/observability-stack/containers.env
/usr/local/sbin/check-s3-backup-rclone.sh /etc/observability-stack/backup.env
```

## Beszel

Checks esperados:

- Todos os sistemas aparecem como up.
- CPU, memoria, disco e rede atualizam.
- Docker stats aparecem nos hosts com Docker.
- Alertas basicos existem por sistema.

Conectividade do host central para agent remoto:

```bash
nc -vz <remote-private-or-tailscale-ip> 45876
```

Conectividade publica deve falhar:

```bash
nc -vz <remote-public-ip> 45876
```

## Troubleshooting

### Dominio retorna 404

Verifique:

- DNS aponta para o host central.
- O dominio esta associado no Dokploy ou no reverse proxy.
- O container esta na rede do reverse proxy.
- A porta interna correta foi configurada: `3001` para Uptime Kuma, `8090`
  para Beszel.

### Cloudflare Access nao protege o painel

Verifique:

- Aplicacao Access cobre o hostname inteiro.
- Politica de allow exige identidade.
- Bypass esta limitado a `/api/push/*`, se existir.
- Ordem das aplicacoes/policies nao deixa o painel publico por engano.

### Push monitor fica DOWN

Verifique:

```bash
sed -E 's#^(UPTIME_KUMA_PUSH_URL=).*#\1<redacted>#' \
  /etc/observability-stack/containers.env
systemctl status --no-pager observability-containers.service
journalctl -u observability-containers.service -n 100 --no-pager
docker inspect <container> --format "{{.State.Status}}"
```

Erros comuns:

- Push URL com token errado.
- Nome de container mudou apos redeploy.
- Container esta `running`, mas healthcheck esta `unhealthy`.
- Script nao tem permissao de executar Docker.

### Backup monitor fica DOWN

Verifique:

```bash
rclone lsf --files-only --recursive "$RCLONE_REMOTE_PATH" | head
systemctl status --no-pager observability-s3-backup.service
journalctl -u observability-s3-backup.service -n 100 --no-pager
```

Erros comuns:

- `RCLONE_REMOTE_PATH` aponta para prefixo errado.
- Backup existe, mas e mais antigo que `MAX_AGE_HOURS`.
- Arquivo existe com tamanho zero.
- Host nao tem credenciais do rclone.

### Beszel system fica pending ou down

Verifique:

```bash
nc -vz <remote-private-or-tailscale-ip> 45876
docker logs --tail=100 observability-beszel-agent-<host-slug>
ufw status numbered
```

Erros comuns:

- `BESZEL_AGENT_KEY` diferente da chave do Hub.
- Agent escutando no IP errado.
- Firewall permite o IP publico mas bloqueia o privado.
- Host central e remoto nao estao na mesma rede privada/VPN.
- Se os hosts estao em provedores diferentes, confirme que Tailscale esta
  ativo nos dois lados e use o IP `100.x.y.z` do host remoto no Beszel.

## Rotina semanal

- Confirmar que todos os monitores estao UP.
- Confirmar que backups recentes existem no destino externo.
- Checar disco dos hosts no Beszel.
- Verificar se alertas de teste chegam por email/Telegram.
- Revisar se algum novo app foi criado sem monitoramento.

## Rotina mensal

- Revisar usuarios dos paineis.
- Revisar policies do Cloudflare Access ou equivalente.
- Testar restore de pelo menos um backup critico.
- Atualizar imagens em ambiente controlado antes de aplicar em producao.
- Revisar [docs/references.md](references.md) quando uma dependencia mudar.

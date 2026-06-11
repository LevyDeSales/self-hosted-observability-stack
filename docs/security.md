# Seguranca

Esta stack coleta dados operacionais sensiveis. Trate paineis, agents e push
URLs como superficie administrativa.

## Politicas

| Area | Politica |
| --- | --- |
| Git | Nunca commitar segredos, `.env` reais, IPs privados sensiveis ou push URLs. |
| Uptime Kuma | Proteger painel com Access/VPN/SSO. |
| Beszel Hub | Proteger painel com Access/VPN/SSO. |
| Beszel Agent | Permitir `45876/tcp` somente do host central por rede privada/VPN. |
| Push URLs | Guardar em arquivo `0600`; tratar como token. |
| SMTP | Guardar senha em secret manager ou arquivo `0600`. |
| Backups | Validar existencia sem expor access key no output. |

## Arquivos recomendados no host

```text
/etc/observability-stack/central.env
/etc/observability-stack/remote-agent.env
/etc/observability-stack/containers.env
/etc/observability-stack/backup.env
```

Permissao:

```bash
chown root:root /etc/observability-stack/*.env
chmod 600 /etc/observability-stack/*.env
```

## Cloudflare Access

Proteja:

```text
https://monitor.example.com/*
https://metrics.example.com/*
```

Bypass opcional:

```text
https://monitor.example.com/api/push/*
```

Use bypass apenas se os hosts que enviam push nao conseguem autenticar via
Access e se a push URL contem token forte. Se possivel, use Service Auth, VPN
ou origem privada em vez de bypass publico.

## Firewall

Host central:

```bash
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow proto tcp from <docker-bridge-cidr> to any port 45876
ufw enable
```

Host remoto:

```bash
ufw allow proto tcp from <central-private-ip> to any port 45876
ufw deny 45876/tcp
ufw enable
```

Valide de fora:

```bash
nc -vz <remote-public-ip> 45876
```

O teste deve falhar.

## Checklist antes de publicar fork

```bash
rg -n "password|secret|token|apikey|api_key|access_key|push/" .
rg -n "real-domain|real-public-ip|customer-name|private-network-id" .
```

Substitua qualquer valor real por placeholder antes de publicar.

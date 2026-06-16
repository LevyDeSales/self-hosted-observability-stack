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
| Tailscale | Usar quando nao houver private network comum entre as VPSs. |
| Push URLs | Guardar em arquivo `0600`; tratar como token. |
| SMTP | Guardar senha em secret manager ou arquivo `0600`. |
| Backups | Validar existencia sem expor access key no output. |

## Modelo de exposicao

Antes de configurar DNS, firewall, Cloudflare Access, Cloudflare Tunnel ou
Tailscale, leia [exposure-model.md](exposure-model.md) e classifique a
topologia.

Pontos de seguranca que nao mudam:

- Cloudflare Access autentica e autoriza no edge; Cloudflare Tunnel cria
  conectividade ate a origem privada. Um nao substitui o outro.
- VPS publica pode usar Access sem Tunnel se o DNS estiver proxied e o firewall
  de origem aceitar HTTP/HTTPS somente dos IPs de origem da Cloudflare.
- Allowlist de IPs da Cloudflare nao basta sozinha: o reverse proxy/origem nao
  deve ter default vhost servindo paineis e deve aceitar apenas hostnames
  esperados, como `monitor.example.com` e `metrics.example.com`.
- Use Authenticated Origin Pulls, mTLS ou Tunnel quando precisar de
  autenticacao mais forte entre Cloudflare e origem.
- Homelab sem IP publico ou origem atras de NAT/CGNAT deve usar Tunnel junto
  com Access para paineis administrativos.
- Beszel Agent `45876/tcp` nunca deve ficar publico.
- Policies de IP no Access usam o IP publico do cliente visto pela Cloudflare.
  Nao use IP Docker, LAN, private IP do provedor ou Tailscale IP como
  allowlist de usuario browser.

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

Access protege identidade no edge da Cloudflare. Tunnel, quando usado, protege
conectividade ate a origem; ele nao substitui policy de Access.

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

Para allowlist de usuario browser, use apenas IP publico de cliente visto pela
Cloudflare, por exemplo `<admin-public-ip>/32`. Nao use IPs privados ou IPs
Tailscale nessa policy.

## Firewall

Host central com DNS proxied pela Cloudflare:

```bash
ufw allow proto tcp from <cloudflare-source-cidr> to any port 80
ufw allow proto tcp from <cloudflare-source-cidr> to any port 443
ufw allow proto tcp from <docker-bridge-cidr> to any port 45876
ufw enable
```

Repita as regras de HTTP/HTTPS para os CIDRs oficiais publicados pela
Cloudflare. Se usar Tunnel, a origem nao precisa aceitar HTTP/HTTPS inbound da
internet.

No reverse proxy, evite default vhost apontando para Uptime Kuma, Beszel Hub ou
outro painel. Sirva paineis somente para hostnames esperados e retorne erro,
fechamento ou uma pagina neutra para Host/SNI desconhecido.

Host remoto:

```bash
ufw allow proto tcp from <central-private-ip> to any port 45876
ufw deny 45876/tcp
ufw enable
```

Host remoto via Tailscale:

```bash
ufw allow in on tailscale0 to any port 45876 proto tcp \
  comment "beszel agent over tailscale"
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

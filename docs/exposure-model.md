# Modelo de Exposicao: Cloudflare Access, Tunnel, Rede Privada e Tailscale

Este documento define o modelo canonico de exposicao para uma stack publica de
observabilidade self-hosted. Use-o antes de abrir portas, criar politicas de
Access, configurar Tunnel, escolher rede privada do provedor ou instalar
Tailscale.

O objetivo e separar tres decisoes:

- como usuarios acessam paineis web;
- como a Cloudflare chega na origem;
- como o trafego interno de metricas passa entre hosts.

## Access e Tunnel nao sao a mesma coisa

| Item | Funcao | O que nao faz |
| --- | --- | --- |
| Cloudflare Access | Autenticacao e autorizacao no edge da Cloudflare para um hostname ou path. | Nao cria conectividade privada ate a origem por si so. |
| Cloudflare Tunnel | Conectividade entre a Cloudflare e uma origem privada sem porta inbound publica na origem. | Nao substitui Access, VPN, SSO ou controle de identidade. |

Regras importantes:

- Access nao exige Tunnel.
- Tunnel nao substitui Access.
- Uma VPS publica muitas vezes pode usar Access sem Tunnel, com DNS proxied e
  firewall de origem limitando HTTP/HTTPS aos IPs de origem da Cloudflare.
- Um homelab sem IP publico, atras de NAT ou CGNAT, deve usar Access + Tunnel.
- Paineis web e trafego interno de metricas sao problemas diferentes. Proteja
  ambos explicitamente.

## Matriz de decisao

| Cenario | Modelo recomendado | Trafego esperado |
| --- | --- | --- |
| Homelab sem IP publico | Access + Tunnel. | Browser -> Cloudflare Access -> Tunnel -> origem privada. |
| VPS com IP publico | Access sem Tunnel, DNS proxied e firewall de origem. | Browser -> Cloudflare Access -> IP publico da VPS, com HTTP/HTTPS aceitos somente da Cloudflare. |
| VPS com rede privada do provedor | Reverse proxy publico + IPs privados do provedor para trafego interno. | Paineis via Access; Beszel Hub -> Beszel Agent por `<private-provider-ip>`. |
| VPSs sem rede privada comum ou em provedores diferentes | Cloudflare Access para paineis web + Tailscale para trafego interno de observabilidade. | Paineis via Access; Beszel Hub -> Beszel Agent por `<tailscale-ip>`. |
| Hibrido | IP publico para entrada, rede privada do provedor para hosts do mesmo provedor, Tailscale para cross-provider, homelab e maquinas admin. | Cada host usa o caminho privado mais restrito disponivel. |

## Regras praticas

- Use Tunnel quando a origem nao tem IP publico, esta atras de NAT/CGNAT ou
  voce nao quer portas inbound abertas na origem.
- Use Access sem Tunnel quando a origem e uma VPS publica com DNS proxied pela
  Cloudflare e firewall de origem limitando HTTP/HTTPS aos IPs de origem da
  Cloudflare.
- Use rede privada do provedor para trafego interno entre servicos quando os
  hosts compartilham a mesma rede privada do provedor.
- Use Tailscale quando nao existe rede privada comum do provedor ou quando os
  hosts cruzam provedores, homelab e maquinas admin.
- Nao abra `45876/tcp` publicamente. Essa porta e exclusiva para trafego
  privado entre Beszel Hub e Beszel Agent.

## Homelab sem IP publico

Use este modelo quando o host nao recebe conexoes inbound confiaveis da
internet, esta atras de NAT/CGNAT ou nao deve expor portas publicas.

Padrao recomendado:

- Publique `monitor.example.com`, `metrics.example.com` e, se existir,
  `dokploy.example.com` por Cloudflare Tunnel.
- Proteja cada hostname ou path administrativo com Cloudflare Access.
- Mantenha a origem sem portas inbound publicas para HTTP/HTTPS.
- Para metricas internas, use Tailscale ou outra rede privada entre o Beszel
  Hub e os Beszel Agents.
- Se ainda nao existe rede privada nem Tailscale, use apenas Uptime Kuma push
  ate configurar um canal privado para metricas.

## VPS com IP publico

Use este modelo quando a origem e uma VPS publica e voce aceita que a
Cloudflare chegue nela pelo IP publico.

Padrao recomendado:

- Configure `monitor.example.com` e `metrics.example.com` com DNS proxied.
- Proteja os paineis com Cloudflare Access.
- Nao use Tunnel apenas por padrao. Tunnel so e necessario se voce quer remover
  portas inbound da origem ou se a origem nao e publicamente alcancavel.
- No firewall da origem, permita HTTP/HTTPS apenas a partir dos IPs de origem
  oficiais da Cloudflare.
- Allowlist dos IPs de origem da Cloudflare e necessaria, mas nao suficiente:
  o reverse proxy/origem tambem deve rejeitar Host/SNI desconhecido e servir
  paineis somente para hostnames esperados, como `monitor.example.com` e
  `metrics.example.com`.
- Prefira Authenticated Origin Pulls, mTLS ou Tunnel quando precisar de
  autenticacao mais forte entre Cloudflare e origem.
- Bloqueie acesso direto aos paineis pelo IP publico `<public-vps-ip>`.
- Mantenha `45876/tcp` fechado na internet publica.

## VPS com IP publico e rede privada do provedor

Use este modelo quando os hosts compartilham uma rede privada do provedor alem
de terem IP publico.

Padrao recomendado:

- Use o IP publico apenas para o reverse proxy de entrada.
- Proteja `monitor.example.com` e `metrics.example.com` com Access, VPN ou SSO.
- Configure Beszel Hub para falar com Beszel Agent por `<private-provider-ip>`.
- Configure o Beszel Agent para escutar em `<private-provider-ip>:45876`.
- Restrinja o firewall do Agent para aceitar `45876/tcp` somente do host
  central pela rede privada do provedor.
- Nao roteie metricas de host/container pela internet publica quando a rede
  privada do provedor esta disponivel.

## VPS sem rede privada comum usando Tailscale

Use este modelo quando os hosts estao em provedores diferentes, nao
compartilham rede privada simples ou precisam incluir homelab e maquinas admin.

Padrao recomendado:

- Use Cloudflare Access para os paineis web.
- Instale Tailscale no host central e em cada host remoto monitorado.
- Configure Beszel Agent para escutar em `<tailscale-ip>:45876`.
- Restrinja o firewall para permitir `45876/tcp` somente pela interface ou CIDR
  Tailscale.
- Use ACLs do Tailscale para limitar quais nodes podem acessar os agents.
- Valide que `45876/tcp` funciona por `<tailscale-ip>` e falha por
  `<public-vps-ip>`.

## Modelo hibrido

Use este modelo quando parte da infra compartilha rede privada do provedor, mas
outra parte esta em provedor diferente, homelab ou maquinas admin.

Padrao recomendado:

- Entrada publica: Cloudflare proxied DNS + Access para paineis web.
- Mesma rede privada do provedor: Beszel por `<private-provider-ip>`.
- Cross-provider, homelab e maquinas admin: Beszel ou administracao por
  `<tailscale-ip>`.
- Documente por host qual caminho e usado: publico, rede privada do provedor ou
  Tailscale.
- Nao misture allowlist de browser com rotas privadas de servidor. Elas sao
  controles diferentes.

## Allowlist de IP no Cloudflare Access

Cloudflare Access avalia o IP do cliente visto pela Cloudflare, nao o IP
privado usado entre servidores.

Use estas regras:

- Para usuarios em browser, uma policy de IP pode usar IPs publicos de cliente,
  como `<admin-public-ip>/32`.
- Nao use IP de bridge Docker, IP de LAN, IP privado do provedor ou IP
  Tailscale como allowlist de usuario browser no Cloudflare Access publico.
- IPs privados e IPs Tailscale servem para roteamento interno server-to-server,
  nao para identidade de browser no edge da Cloudflare.
- Se o operador precisa acessar o painel por browser, a policy deve combinar
  identidade forte com o IP publico que a Cloudflare enxerga.
- Se um servidor precisa chamar outro servidor, resolva isso com rede privada,
  Tailscale, firewall e tokens, nao com allowlist de browser.

## Orientacao especifica para observabilidade

- Uptime Kuma e Beszel Hub sao paineis administrativos. Coloque ambos atras de
  Access, VPN ou SSO.
- Endpoints de push do Uptime Kuma podem ficar acessiveis por HTTPS com tokens
  fortes por monitor. Qualquer bypass deve ser estreito e explicito, por
  exemplo apenas `https://monitor.example.com/api/push/*`.
- Nao aplique bypass amplo em `https://monitor.example.com/*`.
- Beszel Agent `45876/tcp` nunca deve ser aberto publicamente.
- Beszel Agent deve escutar em `<private-provider-ip>` ou `<tailscale-ip>`, com
  firewall restrito ao host central ou aos nodes autorizados.
- Se ainda nao existe rede privada do provedor nem Tailscale, use apenas
  Uptime Kuma push ate configurar um canal privado. Nao publique Beszel Agent
  como atalho temporario.

## Checklist para agentes de IA

Antes de executar mudancas em hosts:

- Classifique a topologia: homelab sem IP publico, VPS publica, VPS com rede
  privada do provedor, hosts sem rede privada comum ou hibrido.
- Escolha o modelo de exposicao antes de abrir portas.
- Proteja `monitor.example.com`, `metrics.example.com` e `dokploy.example.com`
  com Access, VPN ou SSO quando forem paineis administrativos.
- Mantenha metricas internas privadas.
- Verifique que `45876/tcp` falha pela internet publica:
  `nc -vz <public-vps-ip> 45876`.
- Verifique que `45876/tcp` funciona pela rede privada escolhida:
  `nc -vz <private-provider-ip> 45876` ou `nc -vz <tailscale-ip> 45876`.
- Substitua todo valor real por placeholders antes de commitar ou
  publicar: `monitor.example.com`, `metrics.example.com`,
  `dokploy.example.com`, `<public-vps-ip>`, `<private-provider-ip>`,
  `<tailscale-ip>` e `<admin-public-ip>`.

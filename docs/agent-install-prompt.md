# Prompt para Agente de IA

Use este prompt ao enviar o repo para outro agente.

```text
Voce recebeu um repo chamado self-hosted observability stack.

Objetivo: instalar uma stack self-hosted com Uptime Kuma, Beszel, Beszel Agents,
systemd timers, checks de containers, checks de backup via rclone e protecao dos
paineis por Cloudflare Access ou equivalente.

Instrucoes:

1. Leia AGENTS.md primeiro.
2. Leia docs/exposure-model.md, docs/installation.md e docs/security.md antes
   de executar comandos.
3. Classifique a topologia antes de abrir portas ou configurar Cloudflare
   Access, Cloudflare Tunnel ou Tailscale: homelab sem IP publico, VPS
   publica, VPS com rede privada do provedor, hosts sem rede privada comum ou
   hibrido.
4. Escolha e registre o modelo de exposicao: Access + Tunnel, Access sem
   Tunnel com DNS proxied e firewall de origem, rede privada do provedor,
   Tailscale ou modelo hibrido.
5. Pergunte somente os dados que nao conseguir inferir: dominios, hosts, IPs
   privados, se os hosts compartilham private network, provider DNS, SMTP,
   containers criticos, destino de backup e credenciais.
6. Nunca grave segredos no Git ou em mensagens finais.
7. Use rede privada/VPN para Beszel Agent. Se as VPSs nao estiverem na mesma
   private network ou forem de provedores diferentes, instale Tailscale para a
   observabilidade. Nao abra 45876/tcp publicamente.
8. Use os exemplos em examples/docker-compose e examples/env como base.
9. Instale scripts e timers de systemd conforme docs/installation.md.
10. Ao final, rode os checks de aceite em docs/installation.md.
11. Responda com URLs dos paineis, hosts cadastrados, monitores criados, timers
   instalados, validacoes que passaram e pendencias.

Nao finalize ate comprovar:

- Uptime Kuma acessivel no dominio protegido.
- Beszel acessivel no dominio protegido.
- Todos os hosts aparecem UP no Beszel.
- Monitores HTTP/TLS, containers e backup aparecem UP no Uptime Kuma.
- Porta 45876/tcp falha pelo IP publico e funciona pelo IP privado/Tailscale.
- Nenhum segredo entrou no repositorio.
```

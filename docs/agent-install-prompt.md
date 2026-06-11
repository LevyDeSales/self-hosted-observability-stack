# Prompt para Agente de IA

Use este prompt ao enviar o repo para outro agente.

```text
Voce recebeu um repo chamado self-hosted observability stack.

Objetivo: instalar uma stack self-hosted com Uptime Kuma, Beszel, Beszel Agents,
systemd timers, checks de containers, checks de backup via rclone e protecao dos
paineis por Cloudflare Access ou equivalente.

Instrucoes:

1. Leia AGENTS.md primeiro.
2. Leia docs/installation.md e docs/security.md antes de executar comandos.
3. Pergunte somente os dados que nao conseguir inferir: dominios, hosts, IPs
   privados, provider DNS, SMTP, containers criticos, destino de backup e
   credenciais.
4. Nunca grave segredos no Git ou em mensagens finais.
5. Use rede privada/VPN para Beszel Agent. Nao abra 45876/tcp publicamente.
6. Use os exemplos em examples/docker-compose e examples/env como base.
7. Instale scripts e timers de systemd conforme docs/installation.md.
8. Ao final, rode os checks de aceite em docs/installation.md.
9. Responda com URLs dos paineis, hosts cadastrados, monitores criados, timers
   instalados, validacoes que passaram e pendencias.

Nao finalize ate comprovar:

- Uptime Kuma acessivel no dominio protegido.
- Beszel acessivel no dominio protegido.
- Todos os hosts aparecem UP no Beszel.
- Monitores HTTP/TLS, containers e backup aparecem UP no Uptime Kuma.
- Porta 45876/tcp falha pelo IP publico e funciona pelo IP privado.
- Nenhum segredo entrou no repositorio.
```

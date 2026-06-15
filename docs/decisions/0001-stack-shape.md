# ADR 0001: Stack leve de observabilidade self-hosted

Status: accepted

## Contexto

O alvo e monitorar VPSs self-hosted com baixo custo operacional. A stack precisa
ser simples o bastante para instalar por um operador ou agente de IA, mas
completa o bastante para cobrir disponibilidade, metricas basicas, containers,
TLS e backups.

## Decisao

Usar:

- Uptime Kuma para HTTP/TLS e push monitors.
- Beszel para metricas de host/container.
- systemd timers para checks customizados.
- rclone para validar backups remotos.
- Cloudflare Access ou equivalente para proteger paineis.
- Tailscale como fallback de rede privada quando os hosts nao estao na mesma
  private network ou pertencem a provedores diferentes.

## Consequencias

Beneficios:

- Instalacao pequena e compreensivel.
- Poucas dependencias.
- Boa cobertura para operacao inicial de VPSs.
- Checks customizados sao scripts auditaveis.

Limitacoes:

- Nao cobre logs centralizados.
- Nao cobre tracing distribuido.
- Alertas e dashboards sao mais simples que Prometheus/Grafana.
- Parte da configuracao ainda passa pela UI dos apps.
- Tailscale adiciona mais uma dependencia operacional quando nao existe
  private network comum.

## Quando evoluir

Considere Prometheus/Grafana/Loki/Tempo/OpenTelemetry quando:

- Houver muitos servicos e necessidade de queries historicas avancadas.
- Logs precisarem de retencao centralizada.
- Traces forem necessarios para debug de latencia.
- Alertas precisarem de roteamento complexo e deduplicacao.

# Monitoring Target

## Identidade

| Campo | Valor |
| --- | --- |
| App/servico |  |
| Host |  |
| FQDN |  |
| Dono |  |
| Criado em |  |
| Ultima validacao |  |

## Beszel

| Campo | Valor |
| --- | --- |
| System name |  |
| Private IP |  |
| Agent port | `45876` |
| Firewall validado |  |
| Alertas criados |  |

## Uptime Kuma

| Monitor | Tipo | Intervalo | Status esperado |
| --- | --- | --- | --- |
|  | HTTP(s) | 60s | 200-299 |
|  | Push containers | 60s | UP |
|  | Push backup | 3600s | UP |

## Containers criticos

| Container | Motivo | Healthcheck obrigatorio |
| --- | --- | --- |
|  |  |  |

## Backup

| Campo | Valor |
| --- | --- |
| Tipo |  |
| Destino externo |  |
| Rclone path |  |
| Idade maxima |  |
| Restore runbook |  |

## Aceite

- [ ] HTTP monitor UP.
- [ ] TLS expiry ligado.
- [ ] Push containers UP.
- [ ] Push backup UP, se aplicavel.
- [ ] Beszel system UP.
- [ ] Docker stats visiveis.
- [ ] Public IP nao expoe `45876/tcp`.
- [ ] Nenhum segredo entrou no Git.

# Variaveis

Este documento lista variaveis usadas pelos exemplos.

## central.env

| Variavel | Obrigatoria | Uso |
| --- | --- | --- |
| `TZ` | nao | Timezone dos containers. |
| `UPTIME_KUMA_IMAGE` | nao | Imagem do Uptime Kuma. |
| `BESZEL_IMAGE` | nao | Imagem do Beszel Hub. |
| `BESZEL_AGENT_IMAGE` | nao | Imagem do Beszel Agent. |
| `BESZEL_APP_URL` | sim | URL publica do Beszel Hub. |
| `BESZEL_AGENT_KEY` | sim | Chave publica cadastrada no Beszel. |
| `BESZEL_AGENT_LISTEN` | sim | IP privado/Tailscale e porta onde o agent local escuta. |

## remote-agent.env

| Variavel | Obrigatoria | Uso |
| --- | --- | --- |
| `HOST_SLUG` | sim | Sufixo do container remoto. |
| `BESZEL_AGENT_IMAGE` | nao | Imagem do Beszel Agent. |
| `BESZEL_AGENT_KEY` | sim | Chave publica cadastrada no Beszel. |
| `BESZEL_AGENT_LISTEN` | sim | IP privado/Tailscale e porta do host remoto. |

## containers.env

| Variavel | Obrigatoria | Uso |
| --- | --- | --- |
| `UPTIME_KUMA_PUSH_URL` | sim | URL base do push monitor. |
| `REQUIRED_CONTAINERS` | sim | Lista separada por espaco ou virgula. |
| `HEALTHCHECK_CONTAINERS` | nao | Containers que devem ter health `healthy`. |
| `DOCKER_BIN` | nao | Binario Docker, default `docker`. |

## backup.env

| Variavel | Obrigatoria | Uso |
| --- | --- | --- |
| `UPTIME_KUMA_PUSH_URL` | sim | URL base do push monitor. |
| `RCLONE_REMOTE_PATH` | sim | Caminho `remote:bucket/prefix`. |
| `MAX_AGE_HOURS` | nao | Idade maxima do backup, default `26`. |
| `MIN_SIZE_BYTES` | nao | Tamanho minimo do arquivo, default `1`. |
| `RCLONE_CONFIG_FILE` | nao | Config rclone customizado. |
| `RCLONE_BIN` | nao | Binario rclone, default `rclone`. |

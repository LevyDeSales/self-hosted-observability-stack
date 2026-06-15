# Host Inventory

## Ambiente

| Campo | Valor |
| --- | --- |
| Organizacao/projeto |  |
| Dominio base |  |
| Provedor DNS |  |
| Reverse proxy/runtime |  |
| Timezone |  |

## Host central

| Campo | Valor |
| --- | --- |
| Nome |  |
| Provedor |  |
| Regiao |  |
| Public IP |  |
| Private IP |  |
| SSH alias |  |
| Docker instalado |  |
| Dokploy instalado |  |

## Hosts remotos

| Nome | Public IP | Private IP | SSH alias | Apps | Observacoes |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

## Overlay network

Preencha quando as VPSs nao compartilharem private network do mesmo provedor.

| Host | Provider | Tailscale IP | Tailscale hostname | Beszel listen |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## Dominios

| FQDN | Servico | Host | Protecao | Observacoes |
| --- | --- | --- | --- | --- |
| monitor.example.com | Uptime Kuma |  | Access/VPN |  |
| metrics.example.com | Beszel |  | Access/VPN |  |

## Apps monitorados

| App | FQDN | Host | Containers criticos | Backup | Dono |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

## Segredos externos

Nao coloque valores aqui. Registre apenas onde estao guardados.

| Segredo | Local seguro | Observacao |
| --- | --- | --- |
| Uptime Kuma admin |  |  |
| Beszel admin |  |  |
| Beszel agent key |  |  |
| SMTP |  |  |
| Push URLs |  |  |

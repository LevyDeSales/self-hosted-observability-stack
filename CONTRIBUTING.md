# Contributing

Este repo prioriza documentacao operacional que possa ser executada por humanos
e agentes de IA.

## Regras

- Mantenha exemplos genericos. Use `example.com`, `10.0.0.0/24` e placeholders.
- Nao inclua nomes de clientes, IPs reais, dominios privados ou segredos.
- Teste scripts com `bash -n` antes de enviar.
- Quando adicionar uma dependencia, adicione tambem um link oficial em
  [docs/references.md](docs/references.md).
- Quando alterar fluxo de instalacao, atualize [AGENTS.md](AGENTS.md).

## Validacao local

```bash
./scripts/validate-repo.sh
```

Se Docker estiver instalado, o script tambem tenta validar os arquivos Compose.

# Publicacao

Esta pasta foi pensada para virar um repo publico separado do repo privado de
infra.

## Validar antes de publicar

```bash
cd observability-stack
./scripts/validate-repo.sh
FORBIDDEN_PATTERNS='cliente-real|dominio-real|ip-real|token-real' \
  ./scripts/validate-repo.sh
```

Revise manualmente:

```bash
rg -n "password|secret|token|apikey|api_key|access_key|push/" .
git status --short
```

Os exemplos contem palavras como `token` por design. O que nao pode existir e
valor real.

## Criar repo local

Rode dentro de `observability-stack`, nao na raiz do repo privado:

```bash
git init -b main
git add .
git commit -m "Document self-hosted observability stack"
```

## Publicar no GitHub com gh

```bash
gh repo create self-hosted-observability-stack \
  --public \
  --source . \
  --remote origin \
  --push
```

Depois de publicar, abra a action `validate` e confirme que passou.

## Publicar manualmente

```bash
git remote add origin git@github.com:<owner>/self-hosted-observability-stack.git
git push -u origin main
```

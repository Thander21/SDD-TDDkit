# Perfil powershell

> **Prontidão:** Levantamento <!-- Levantamento | Requisitos | Pronto | Adiado | Descartado -->
> **Regra:** `.agents/rules/sdd-fluxo.md` §2. **Skill:** `backlog-refinement`.
> Arquivo: `<specs>/backlog/NN - Tema.md`; sem `NN` = provisório até o usuário numerar.

## Levantamento

Achados do bootstrap deste repositório, 12/10/2026:

- `SpecSimpleKit/profiles/powershell.json` nasceu como rascunho para o
  dogfooding. Sondas certas: `carga` (confiança `build`), `falha` e `zero`
  (confiança só `exit`).
- Sem relatório estruturado: o goal vai anotar "RED classificado só pelo
  exit code". Proposta a conferir: `tests/helpers.ps1` emitir JUnit em
  `{relatorio}`.
- Gate `full` = suíte inteira do kit, 472 s nesta máquina; com
  `commit_gate: full` (escolha do usuário), cada commit leva ~8 min.
- Gate `light` cobre sintaxe e ASCII; falta o orçamento de tamanho do
  Markdown gerenciado (README, Regras de manutenção 2: hoje 39,5 KB de
  40 KB no kernel).
- O caminho da suíte no perfil do kit (`tests/run_all.ps1`) não serve na
  raiz deste repositório (`SpecSimpleKit/tests/run_all.ps1`); ajustado à mão
  no `.sdd/profile.json`.
- `validate` deu `INSTAVEL` quando a árvore mudou durante os 8 min da suíte.

Tag provável: `contrato-do-motor` (formato de relatório lido pelo motor).

## Requisitos

<!-- Preenchido pela skill backlog-refinement. -->

### Problema e valor

### Estado atual no código

| Item do levantamento | Existe hoje? | Evidência |
|---|---|---|

### Requisitos funcionais

### Regras de negócio e restrições

### Fora de escopo

### Recorte proposto

| Unidade | Nível | Capacidade | `risk` | Depende de |
|---|---|---|---|---|

### Perguntas para o usuário

### Respostas

| # | Resposta | Data |
|---|---|---|

## Tasks

## Encaminhamento

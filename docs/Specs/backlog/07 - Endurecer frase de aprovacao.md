# Endurecer frase de aprovação

> **Prontidão:** Levantamento <!-- Levantamento | Requisitos | Pronto | Adiado | Descartado -->
> **Regra:** `.agents/rules/sdd-fluxo.md` §2. **Skill:** `backlog-refinement`.
> Arquivo: `<specs>/backlog/NN - Tema.md`; sem `NN` = provisório até o usuário numerar.

## Levantamento

Achados PLAUSÍVEIS da 4ª verificação da CHG-002 (16/10/2026), não
bloqueantes, e um candidato de simplificação do fecho:

- **P-1:** citação de outra change com dígito não ASCII ou letra colada é
  ignorada ("aprovo P1 da change 01 e change ٣", "change 03x e change 01"
  aprovam a 01). `SpecSimpleKit/kernel/tools/sdd/sdd.ps1`, `Test-SddFraseAprovacao`.
- **P-2:** `[int]` sobre o NN da linha de comando lança exceção com NN
  gigante (`approve 99999999999 P1 --frase ...` sai ERRO exit 2).
- **Simplificação:** tirar o `[int]` e comparar `($NN -replace '\D','').TrimStart('0')`
  como texto; fecha o P-2 e encurta a função.

Nível provável: pequeno (correção sem mudar a regra D10). Tag: `portao-humano`.

## Requisitos

## Tasks

## Encaminhamento

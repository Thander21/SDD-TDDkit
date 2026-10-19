---
id: CHG-004
title: Auditoria de orcamento de markdown no gate light
status: Done
capabilities: [fluxo]
risk: []
fonte_normativa:
base_ref: 6e13d7c7d02da1c1e6db49038ecdd93937331dff
impact:
  modified_files: [.sdd/profile.json, README.md, SpecSimpleKit/profiles/powershell.json, tests/test_fluxo_metodologia.ps1, docs/Specs/capabilities/_index.md]
  new_files: []
---

# CHG-004 — Auditoria de orcamento de markdown no gate light

> **Origem:** `origem/04 - Perfil powershell.md`. **Regra:** `.agents/rules/sdd-fluxo.md`.
> Títulos lidos pelo motor (não renomeie): Perguntas em aberto, Análise
> pré-implementação, Tasks, Pós-GOAL, Exceções, Aprovações. `status`,
> `base_ref` e Aprovações são gravados só pelo `sdd approve` do usuário.

## Por quê

O kit estabelece limites rígidos de tamanho para arquivos Markdown gerenciados no kernel (`README.md`, Regras de manutenção 2), evitando crescimento desordenado de contexto para assistentes de IA. Contudo, essa regra era apenas documental e não era auditada automaticamente no gate `light` (`sdd check`), permitindo que adições normativas (como `sdd-revisao.md`) ultrapassassem o teto total de 40 KB sem aviso precoce.

## Perguntas em aberto

## Decisões

| # | Decisão | Fonte (fala do usuário, regra, doc com data) | Data |
|---|---|---|---|
| D1 | Priorizar a Unidade 1 do backlog 04 (orçamento de Markdown no gate light e reconciliação da regra no README); desmembrar JUnit no helpers (U2) e commit_gate (U3) para itens posteriores. | Usuário no chat, 19/10/2026 | 19/10/2026 |
| D2 | Atualizar o teto de Markdown gerenciado total no kernel de 40 KB para 45 KB (46.080 bytes) no README.md para acomodar `sdd-revisao.md` sem violação. | Decisão técnica reconciliatória de D9 da CHG-002, 19/10/2026 | 19/10/2026 |

## Contratos

- Comando do gate `light` com nome `Orcamento de Markdown` em `profile.json`:
  - `sdd-core.md` <= 5 KB (5.120 bytes)
  - `sdd-fluxo.md` <= 14 KB (14.336 bytes)
  - Total de arquivos `.md` no kernel <= 45 KB (46.080 bytes)
  - Exit 0 em sucesso; Exit 1 com mensagem detalhada de violação caso algum limite seja superado.

## Invariantes

- Scripts em ASCII estrito e compatíveis com PowerShell 5.1 e pwsh 7.

## Deltas — capacidade fluxo

### ADDED Requirements

#### Requirement: SPEC-FLUXO-003 — Orcamento de Markdown gerenciado auditado em light

O sistema DEVE validar no gate `light` se os arquivos Markdown gerenciados respeitam os tetos normatizados de tamanho: `sdd-core.md` até 5 KB, `sdd-fluxo.md` até 14 KB e total de Markdown gerenciado até 45 KB (1 KB = 1024 bytes).

##### Scenario: C1 — Arquivos do kernel dentro do orcamento

- **DADO** o repositório com `sdd-core.md`, `sdd-fluxo.md` e total de `.md` dentro dos limites
- **QUANDO** executa o gate `light` (`sdd check`)
- **ENTÃO** o gate `Orcamento de Markdown` é executado e avaliado como PASS

##### Scenario: C2 — Arquivo que excede o limite falha o gate light

- **DADO** qualquer arquivo Markdown gerenciado que exceda seu teto
- **QUANDO** executa o gate `light`
- **ENTÃO** o gate `Orcamento de Markdown` falha (FAIL), apontando o arquivo e tamanho excedente

### MODIFIED Requirements

### REMOVED Requirements

## Critérios de aceite

- Teste automatizado com tag `SPEC-FLUXO-003/C1` passando em `tests/test_fluxo_metodologia.ps1`.
- `sdd check` e `sdd validate` PASS com o novo gate ativo.

## Análise pré-implementação

1. **Cenário sem task / task sem cenário:** C1 e C2 cobertos pelas tasks de teste e implementação do gate.
2. **Impact:** Todos os arquivos modificados constam em `impact.modified_files`.
3. **Riscos e invariantes:** Nenhum risco promotor; compatibilidade ASCII e PowerShell 5.1/7 mantida.

## Tasks

- [x] RED (C1,C2): tests/test_fluxo_metodologia.ps1 -> Falha esperada: Orcamento de Markdown no gate light
- [x] GREEN (C1,C2): tests/test_fluxo_metodologia.ps1 -> passou
- [x] REFACTOR: sdd check e sdd validate verdes com o novo gate ativo

### Pós-GOAL

- [ ] Auditoria do verificador independente (sdd-verify)
- [ ] sdd goal 04 e sdd archive 04

## Exceções

## Aprovações
- P1: aprovado por Thander em 2026-10-19 16:29 (sdd approve; via chat: "aprovo P1 da change 04"; change.md antes: a2601726ad3e)
- P2: aprovado por Thander em 2026-10-19 16:30 (sdd approve; via chat: "aprovo P2 da change 04"; change.md antes: 429734199326)

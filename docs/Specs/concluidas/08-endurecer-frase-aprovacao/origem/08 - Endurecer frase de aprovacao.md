# Endurecer frase de aprovação

> **Prontidão:** Pronto <!-- Levantamento | Requisitos | Pronto | Adiado | Descartado -->
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

### Problema e valor

- **Quem sofre:** Desenvolvedor ou agente executando aprovações de portão (`sdd approve`).
- **O que dá errado hoje:**
  1. Se a frase do usuário contiver menções inválidas ou ambíguas a outras changes (com dígitos não ASCII, sufixos alfabéticos ou identificadores colados como "change 03x" ou "change ٣") ao lado da change alvo, a regex atual ignora o token espúrio e aprova a change erroneamente em vez de recusar por ambiguidade.
  2. Se a linha de comando passar um identificador com muitos dígitos (ex.: `sdd approve 99999999999 P1 --frase ...`), a conversão `[int]` em `Test-SddFraseAprovacao` lança `OverflowException` não tratada, abortando o script com `ERRO` (exit 2) em vez de validar controladamente e retornar `RECUSADO` (exit 1).
- **O que melhora:** Validação estrita e determinística da frase de aprovação humana, sem brecha para menções espúrias a outras changes e sem risco de quebra por estouro de tipo numérico.

### Estado atual no código

| Item do levantamento | Existe hoje? | Evidência |
|---|---|---|
| P-1: citação ignorada se tiver dígito não ASCII ou sufixo colado | Sim | [SpecSimpleKit/kernel/tools/sdd/sdd.ps1:1024](file:///c:/_Projetos/Agentic%20AI%20Engineer/ferramentas%20de%20estudo/SDD-TDDkit/SpecSimpleKit/kernel/tools/sdd/sdd.ps1#L1024): regex `\b(?:change|chg)[\s\-_:#]*([0-9]+)\b` exige dígitos ASCII com boundary `\b`, ignorando menções como `change 03x` ou `change ٣` |
| P-2: `[int]` estoura com NN gigante | Sim | [SpecSimpleKit/kernel/tools/sdd/sdd.ps1:1017](file:///c:/_Projetos/Agentic%20AI%20Engineer/ferramentas%20de%20estudo/SDD-TDDkit/SpecSimpleKit/kernel/tools/sdd/sdd.ps1#L1017): `$num = [int]($NN -replace '\D', '')` falha com `OverflowException` |
| Simplificação: remover `[int]` | Hipótese | A linha 1022 já tem comentário propondo comparação como texto sem zeros à esquerda, mas a linha 1017 ainda faz cast para `[int]` |

### Requisitos funcionais

- **RF1:** O motor DEVE recusar a aprovação (exit 1, `RECUSADO`) se a frase contiver qualquer menção a "change" ou "chg" seguida de identificador que não corresponda exatamente ao número da change alvo (incluindo sufixos, caracteres não numéricos ou menções adicionais que não casem estritamente com o alvo).
- **RF2:** O motor DEVE processar identificadores numéricos como texto normalizado (sem zeros à esquerda), sem realizar coerção para `[int]`, garantindo que NNs longos não causem estouro de tipo nem aborto inesperado do script (retornando `RECUSADO` com exit 1 quando inválido).

### Regras de negócio e restrições

- **RN1:** Números isolados que não estão associados a "change" ou "chg" (ex.: datas como "01/10" ou o próprio número do portão "P1") continuam não contando como número da change e não invalidam a frase por si sós (fonte: regra D10 da CHG-002, [SpecSimpleKit/kernel/tools/sdd/sdd.ps1:1020-1021](file:///c:/_Projetos/Agentic%20AI%20Engineer/ferramentas%20de%20estudo/SDD-TDDkit/SpecSimpleKit/kernel/tools/sdd/sdd.ps1#L1020-L1021) e [capabilities/motor/spec.md:15-21](file:///c:/_Projetos/Agentic%20AI%20Engineer/ferramentas%20de%20estudo/SDD-TDDkit/docs/Specs/capabilities/motor/spec.md#L15-L21)).
- **RN2:** Invariante de portão humano: na dúvida ou presença de qualquer referência conflitante / espúria a outra change, o comando DEVE recusar (exit 1) e nada deve ser gravado (fonte: [AGENTS.md: Riscos do projeto](file:///c:/_Projetos/Agentic%20AI%20Engineer/ferramentas%20de%20estudo/SDD-TDDkit/AGENTS.md)).
- **RN3:** Contrato do requisito [SPEC-MOTOR-001/C3](file:///c:/_Projetos/Agentic%20AI%20Engineer/ferramentas%20de%20estudo/SDD-TDDkit/docs/Specs/capabilities/motor/spec.md#L35-L40): permanece ativo, sendo endurecido para cobrir os novos cenários de recusa sem alterar a interface do comando.

### Fora de escopo

- Alteração da lógica de verificação de portão no terminal humano interativo (apenas a validação de `--frase` e `$NN` em `Test-SddFraseAprovacao` é alterada).
- Mudança na semântica das tags de aprovação gravadas no `change.md`.

### Recorte proposto

| Unidade | Nível | Capacidade | `risk` | Depende de |
|---|---|---|---|---|
| Endurecimento de `Test-SddFraseAprovacao` | Feature (promovido por risco `portao-humano`) | `motor` | `portao-humano` | — |

> **Nota sobre o nível:** O levantamento sugeria "Pequeno (correção sem mudar a regra D10)", mas a tabela de Riscos do [AGENTS.md](file:///c:/_Projetos/Agentic%20AI%20Engineer/ferramentas%20de%20estudo/SDD-TDDkit/AGENTS.md) define que a tag `portao-humano` **promove a Feature** (`Promove a feature? sim`).

### Perguntas para o usuário

1. **Numeração e Nível:** O item estava numerado como 07, mas a CHG-007 já foi concluída. Como a tag `portao-humano` promove a feature no AGENTS.md, abrir como Feature (CHG-008) ou manter Pequeno?

### Respostas

| # | Resposta | Data |
|---|---|---|
| 1 | Abrir como Feature com CHG-008 (promovido pelo risco `portao-humano` em `AGENTS.md`) e renomear o item de backlog para `08 - Endurecer frase de aprovacao.md`. | 2026-10-19 |

## Tasks

## Encaminhamento

- Aberta CHG-008 (`docs/Specs/changes/08-endurecer-frase-aprovacao/change.md`) em `Draft`. Origem movida para `changes/08-endurecer-frase-aprovacao/origem/`.


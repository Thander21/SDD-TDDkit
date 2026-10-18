# Ideias do fluxo do PDV D+

> **Prontidão:** Pronto <!-- Levantamento | Requisitos | Pronto | Adiado | Descartado -->
> **Regra:** `.agents/rules/sdd-fluxo.md` §2. **Skill:** `backlog-refinement`.
> Arquivo: `<specs>/backlog/NN - Tema.md`; sem `NN` = provisório até o usuário numerar.

## Levantamento

Fala do usuário, 16/10/2026:

> analise o nosso fluxo de sdd no pdvd+ que estou ajustando sempre arrumando
> o que falha enquanto o kit nao fica pronto podemos ir pegando as ideias e
> melhorias para aplicar aqui. o fluxo esta mais redondo la e automatico
> pedindo as permissoes no momento certo e rodando os agentes e comandos de
> forma automatica, por mais que la seja fixo no claudecode e aqui é mais
> generico podemos manter as ideias e validar se cada ide ou ia nao tiver os
> mesmos comandos deve rodar algo mais manual como codereview ou learn tendo
> apenas uma ideia do conceito no sdd

Análise só de leitura em 16/10/2026 (`C:\_Projetos\ERP PDV D+`, prefixo
`PDV:`). Fonte principal: `PDV:.agents/usage/USAGE_Spec_Flow.md`,
`PDV:.agents/rules/specdriven.md`, CHG-112 arquivada.

**Por que lá é "mais redondo":** a CHG-112 do PDV contou 12 paradas numa
feature de 3 fases, das quais só 5 eram decisão do usuário. A regra passou a
ser "parar só em autorização ou pergunta que muda o resultado; o resto segue
sem pedido" (`PDV:specdriven.md:134-137`). É texto de regra, não mecanismo.

| # | Ideia | Onde no PDV | Hoje no kit | Passo manual se a IDE não tiver o recurso | Esforço |
|---|---|---|---|---|---|
| 1 | Paradas só em Pronto, P1, P2, pergunta, exceção, 3 falhas e commit; o resto segue sem pedido | `specdriven.md:134-137` | cada etapa espera pedido (`como-usar-fluxo.md` §4) | nenhuma (texto) | baixo |
| 2 | "Pronto" já abre a change; P1 já segue para plano, tasks e análise | `backlog_refinement/SKILL.md:68-72` | "abra o item NN" é pedido | nenhuma | baixo |
| 3 | Fecho fixo após GOAL PASS: archive → learn → validate → texto do commit → parada | `USAGE:389-417` | archive a pedido; sem texto de commit | sem `/learn`: seção "Lições" no chat com os 4 destinos | baixo/médio |
| 4 | Micro-loop por fase com linha SIMPLIFY e `> Bloqueio:` na 3ª falha do mesmo passo | `_templates/tasks.md:46-54` | só RED/GREEN/REFACTOR | sem `/simplify`/`/code-review`: aplicar `sdd-revisao.md` ao diff da fase | médio |
| 5 | Verificação em ordem fixa com revisão extra puxada pela tag de risco | `specdriven.md:335-341` | validate → verificador → goal | revisão por `sdd-revisao.md` em sessão nova | baixo |
| 6 | Teto de turnos e custo por fase na condição de parada | `USAGE:355-364` | só "declara teto" | usuário pede fase a fase; `sdd goal` no fim de cada uma | médio |
| 7 | GOAL BLOCKED no motor com `--unblock` só do usuário | `specdriven.md:350-354` | 3 falhas é honra | `--unblock` só com frase/terminal | médio (`contrato-do-motor`) |
| 8 | Seção `## Sequência` no item com várias unidades | `backlog_refinement/SKILL.md:79-83` | sem mapa de ordem | nenhuma | baixo |
| 9 | Learn automático no fecho: pendência e memória direto, regra só proposta | `.claude/skills/learn/SKILL.md:73-82` | learn propõe tudo | idem 3 | baixo |
| 10 | Matriz de testes leve revisada antes do P2 | `specdriven.md:149-158` | só Análise | sessão nova | médio |
| 11 | Digest antes de compactar (hook PreCompact, só no projeto) | `precompact_digest.ps1` | "releia a change" | regra atual | médio |
| 12 | Guia "você só aparece nas paradas" | `USAGE:520-537` | tabela com um pedido por etapa | — | baixo |
| 13 | Tabela de capacidades por IDE (subagente, hook, revisão, loop, pergunta, learn) com o passo manual | o PDV restringe ao Claude | só o `sdd-verify` degrada | é a própria tabela; fora do kernel | médio |
| 14 | Perguntas estruturadas da IDE quando houver | `backlog_refinement/SKILL.md:62-65` | uma por vez | texto no chat | baixo |

**Não trazer:** autorização de série (conflita com `portao-humano`); ledger
por hook que lê o comando (o `sdd test` é mais portátil); regras específicas
do ERP e do Flutter; aparato pesado (hash da matriz, séries, worktrees,
waivers); `git rm` do item (o kit preserva em `origem/`); sintaxe `/goal` e
teto em US$ dentro do kernel (vai para o doc por IDE; orçamento de 40 KB);
qualquer hook global.

**Top 5 da análise:** (1) ideias 1, 2 e 12; (2) ideias 3 e 9; (3) ideia 5;
(4) ideias 13 e 6, fora do kernel; (5) ideia 4 e depois a 7.

Não verificado: recursos de Cursor, Codex e Gemini CLI (hooks, subagentes,
loop com teto); se 1-3 cabem nos 40 KB sem corte.

Decisão do usuário, 16/10/2026 (aplicada já na CHG-002): "sim o maximo de
passos possiveis se ja fez o code review, simplify, segurança e learn seja com
comandos da ia ou manualmente relendo pode finalizar e arquivar automatico so
aguardar o commit" (ideias 1, 3 e 5; a única parada no fecho é o commit).

## Requisitos

Refinamento em 18/10/2026. Proposta de comportamento futuro; não altera as
regras vigentes nem autoriza implementação. O Levantamento foi preservado.

### Problema e valor

O desenvolvedor precisa pedir transições que não exigem uma decisão nova.
O kit deve conduzir o trabalho entre os portões, preservar as aprovações
humanas e explicar como executar a revisão quando não houver comando nativo.

### Estado atual no código

| Ideias | Existe hoje? | Evidência conferida nesta rodada |
|---|---|---|
| 1, 2, 12: continuidade e guia de paradas | Parcial: P1 já leva a plano/tasks/análise no guia, mas Pronto ainda sugere outro pedido para abrir | `SpecSimpleKit/docs/como-usar-fluxo.md:121-124`; `SpecSimpleKit/kernel/.agents/skills/backlog-refinement/SKILL.md:32-36` |
| 3: archive automático | Não como regra geral; exige pedido do usuário | `SpecSimpleKit/kernel/.agents/rules/sdd-fluxo.md:60`, `:162`; `SpecSimpleKit/kernel/.agents/skills/sdd-verify/SKILL.md:51-54` |
| 4, 5: simplificação e revisão por risco | Há Verify Pass de change; não há sequência explícita de simplificação, segurança por risco e fecho por fase | `SpecSimpleKit/kernel/.agents/rules/sdd-revisao.md:34-50` |
| 6: teto de execução | Já exige teto de turnos/custo, sem política por IDE ou aferição automática | `SpecSimpleKit/kernel/.agents/rules/sdd-core.md:51-52`; `SpecSimpleKit/kernel/.agents/skills/sdd-verify/SKILL.md:53-54` |
| 7: bloqueio persistente | Não existe GOAL BLOCKED/--unblock no despacho atual; goal emite PASS/FAIL; proposta já reconhecida no documento do método | `SpecSimpleKit/kernel/tools/sdd/sdd.ps1:950-956`, `:1281`; `SpecSimpleKit/Metodologia SDD.ai:293` |
| 8, 14: sequência e perguntas | Skill exige uma pergunta por vez; molde não tem Sequência nem preferência por pergunta estruturada | `SpecSimpleKit/kernel/.agents/skills/backlog-refinement/SKILL.md:26-28`; `SpecSimpleKit/kernel/Docs/Specs/_templates/backlog.md:38-50` |
| 9: learn automático | Skill do Claude propõe pendência/upstream/regra; preferência pessoal é exceção; não há fecho automático descrito | `SpecSimpleKit/kernel/.claude/skills/learn/SKILL.md:19-41` |
| 10: matriz de testes | Há análise de cenário/task/impact/invariante; matriz separada não é exigida | `SpecSimpleKit/kernel/.agents/rules/sdd-fluxo.md:66-70` |
| 11: digest | Não encontrado hook PreCompact no produto; regra atual manda reler a change | busca literal por `PreCompact` em `SpecSimpleKit/`, sem ocorrência; `SpecSimpleKit/kernel/.agents/rules/sdd-fluxo.md:177-178` |
| 13: fallback por IDE | Verificador distingue Claude/subagente e Antigravity/sessão nova; não há matriz geral para as ferramentas citadas | `SpecSimpleKit/kernel/.agents/skills/sdd-verify/SKILL.md:8-13` |
| Orçamento | Limites documentados, não comprovados por gate dedicado nesta rodada | `SpecSimpleKit/Metodologia SDD.ai:316-317` |

A spec viva de `motor` foi lida: `docs/Specs/capabilities/motor/spec.md`
(SPEC-MOTOR-001). A proposta inicial não altera esse requisito nem o
contrato de aprovação. A capacidade `fluxo` ainda não tem spec viva
(`docs/Specs/capabilities/_index.md`).

### Requisitos funcionais propostos

- **RF1 (U1):** depois de o usuário marcar o item Pronto, abrir a change
  Draft ou preparar as Tasks do pequeno sem pedir outra autorização. Depois
  de P1, produzir plano, tasks e análise até P2; depois de P2, executar o
  escopo aprovado. Não atravessar P1/P2 por inferência.
- **RF2 (U1):** depois da implementação, executar simplificação, revisão de
  código e segurança proporcional aos riscos, validate, verificação
  independente e goal. Só GOAL PASS definitivo permite archive automático;
  PASS em modo pre-verify não permite. Achado que altera código exige nova
  validação e verificação da árvore resultante.
- **RF3 (U1):** após archive, consolidar lições, executar validate sobre o
  resultado final e entregar texto de commit com pendências explícitas.
  Falha interrompe o fecho; commit/push/merge continuam sob pedido específico.
- **RF4 (U1):** sem comando nativo de revisão/simplificação/learn, executar
  o conceito pelas regras e registrar evidência ou limitação. A releitura
  do implementador não substitui a verificação independente: sem contexto
  independente disponível, informar o impedimento e aguardar essa revisão.
- **RF5 (U1):** learn deve evitar duplicação, encaminhar pendências ao
  backlog e apresentar propostas de regra/upstream sem aplicar regras por
  iniciativa própria. Memória respeita a autorização e a política do ambiente;
  ausência de permissão não impede apresentar a lição no chat.
- **RF6 (U2):** itens com várias unidades devem informar ordem, dependências
  e estado de cada unidade, preservando a origem. Perguntas devem usar recurso
  estruturado quando disponível e texto equivalente quando ausente.
- **RF7 (U3):** o guia deve distinguir capacidades verificadas por ambiente,
  indisponíveis e não verificadas, com alternativa manual e indicação de
  como declarar teto de execução sem inventar medição de custo/turnos.

Fonte de RF1-RF5: intenção e decisão de 16/10/2026 no Levantamento;
RF6-RF7 são propostas derivadas das ideias 6, 8, 13 e 14, ainda sem aceite.

### Regras de negócio e restrições

- **RN1:** só o usuário marca Pronto e aprova P1/P2, com a frase exigida;
  não trazer autorização em série (núcleo vigente e exclusões do Levantamento).
- **RN2:** nunca enfraquecer a independência do verificador, preservar
  evidência do motor e não editar status/base_ref/Aprovações à mão
  (`sdd-core.md`, seções Fluxo e O que é imposto e o que é honra).
- **RN3:** não gravar hooks globais, copiar regras do ERP ou apagar a origem
  do backlog (Levantamento; `AGENTS.md`, riscos e fonte/cópia).
- **RN4:** implementação futura altera o kernel e sincroniza via instalador;
  cópias gerenciadas da raiz não são editadas manualmente (`AGENTS.md`).
- **RN5:** manter os limites de 5 KB/core, 14 KB/fluxo e 40 KB/Markdown do
  núcleo documentados no método; medir o conjunto antes de implementar e
  após a alteração (`SpecSimpleKit/Metodologia SDD.ai:316-317`).
- **RN6:** RF2-RF3 mudam a política de fecho, não a última linha ou o estado
  persistido do motor. GOAL BLOCKED exige unidade própria e migração do contrato.

### Recorte proposto

| Unidade | Nível | Capacidade | `risk` | Depende de |
|---|---|---|---|---|
| U1 — Continuidade entre portões e fecho automático (ideias 1, 2, 3, 5, 9, 12) | Feature: política de passagem por portões e arquivo do usuário | fluxo | portao-humano, arquivo-do-usuario | aceite do recorte; P1/P2 próprios na futura change |
| U2 — Sequência e perguntas portáveis (8, 14) | Pequeno: ajuste de artefato existente, sem campo lido pelo motor | fluxo | nenhuma promotora identificada | U1, para alinhar as transições |
| U3 — Guia de capacidades e limites por ambiente (6, 13) | Pequeno: documentação, sem promessa de suporte novo | fluxo | nenhuma promotora identificada | U1; pesquisa documental na execução |

### Fora do primeiro recorte — propostas para avaliação posterior

- Ideia 4: loop por fase com SIMPLIFY/Bloqueio; separar da simplificação
  do fecho de U1 para não criar agora um segundo protocolo de execução.
- Ideia 7: bloqueio persistente e desbloqueio humano; feature `motor`, risco
  `contrato-do-motor` e `portao-humano`, com cenários e migração próprios.
- Ideia 10: matriz separada antes do P2; avaliar se acrescenta cobertura à
  análise existente antes de tornar outro artefato obrigatório.
- Ideia 11: digest/hook local; feature de integração por ambiente, depende
  de confirmar suporte e compatibilidade com a CHG-005. Não criar hook agora.
- Implementar novos adaptadores de IDE, copiar orçamento em US$ do PDV,
  instalar configuração global ou modificar as changes 01/05.

### Perguntas para o usuário

- **Q1:** aceita começar por U1 e manter U2/U3 como próximas unidades,
  deixando as ideias 4, 7, 10 e 11 para avaliação posterior? Recomendação:
  sim, para entregar a continuidade já decidida sem ampliar o motor agora. Respondida em D2.

### Respostas

| # | Resposta | Data |
|---|---|---|
| D1 | Decisão já registrada no Levantamento: automatizar o fecho com revisão, simplificação, segurança e learn, aguardando o commit. Não equivale a P1/P2 desta iniciativa. | 16/10/2026 |

| D2 | Usuário respondeu "ok continue" após a pergunta para marcar Pronto e abrir a change: marcação Pronto e aceite de U1 primeiro, U2/U3 depois; ideias 4, 7, 10 e 11 ficam para avaliação posterior. Não equivale à aprovação P1/P2. | 18/10/2026 |

## Tasks

Não abertas: refinamento de item com unidade feature; recorte aceito; Pronto marcado pelo usuário.

## Encaminhamento

18/10/2026: Q1 respondida em D2 e item marcado Pronto após "ok continue". U1 aberta como CHG-006 Draft; origem preservada em changes/06-continuidade-e-fecho/origem/. IDs SPEC serão reservados no P1. U2/U3 continuam sequenciadas para depois.

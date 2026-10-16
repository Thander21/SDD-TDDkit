# Ideias do fluxo do PDV D+

> **Prontidão:** Levantamento <!-- Levantamento | Requisitos | Pronto | Adiado | Descartado -->
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

<!-- Preenchido pela skill backlog-refinement. -->

## Tasks

## Encaminhamento

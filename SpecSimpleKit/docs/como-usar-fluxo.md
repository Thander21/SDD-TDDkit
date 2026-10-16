# Como usar o SpecSimpleKit: o fluxo

> Guia para quem usa o kit pelo chat da IA (Claude Code, Antigravity). A
> regra que a IA segue está em `kernel/.agents/rules/sdd-fluxo.md`; este
> documento explica o mesmo fluxo para pessoas. Versão de 14/10/2026
> (aprovação pelo chat desde a CHG-002).

## 1. Do pedido ao código pronto

Você só escreve no chat. A IA roda os comandos; o motor (`tools/sdd/sdd.ps1`)
e os guards conferem e gravam.

```text
 VOCÊ (chat)                         IA                              MOTOR / GUARD
 ───────────                         ──                              ─────────────
 ideia em texto ─────────────► backlog/NN - Tema.md
                               Prontidão: Levantamento
                                      │
 "refine o item NN" ──────────► skill backlog-refinement
                               confere o código (arquivo:linha)
                               escreve RF / RN / recorte
                               faz perguntas, 1 por vez ◄──── respostas viram R1, R2...
                               Prontidão: Requisitos
                                      │
 lê, edita e diz "Pronto" ────► Prontidão: Pronto          (só você muda isso)
                                      │
 "abra o item NN" ────────────► cria changes/NN-slug/change.md (Draft)
                               MOVE o item para changes/NN-slug/origem/
                               reserva os IDs SPEC-DOM-NNN no _index.md
                                      │
                         ┌────────────┴────────────┐
                         │ Etapa 1  Especificação  │  Por quê + cenários DADO/QUANDO/ENTÃO
                         │ Etapa 2  Clarificação   │  "Perguntas em aberto" vazia
                         └────────────┬────────────┘
                                      │
 ╔════════════ P1 ═════════════╗      │
 ║ você no chat: "aprovo P1    ║ ─────┼──────────────────────────► sdd approve NN P1 --frase
 ║  da change NN"              ║      │                              status: Approved
 ╚═════════════════════════════╝      │
                         ┌────────────┴────────────┐
                         │ Etapa 3  Plano          │  Decisões, Contratos, Invariantes, impact
                         │ Etapa 4  Tasks          │  RED → GREEN → REFACTOR por cenário
                         │ Etapa 5  Análise        │  cenário sem task? arquivo fora do impact?
                         └────────────┬────────────┘
 ╔════════════ P2 ═════════════╗      │
 ║ "aprovo P2 da change NN"    ║ ─────┼──────────────────────────► sdd approve NN P2 --frase
 ╚═════════════════════════════╝      │                              status: In-Implementation
                                      │                              base_ref = HEAD
                         ┌────────────┴────────────┐
                         │ Etapa 6  Implementação  │
                         │  por cenário:           │
                         │   escreve o teste ──────┼──► sdd test <alvo>  → RED  (falha)
                         │   escreve o código ─────┼──► sdd test <alvo>  → GREEN (passou)
                         │   refatora              │       grava evidence.jsonl
                         └────────────┬────────────┘
                                      │
                               sdd validate (gates completos) ──► last-full.json
                               verificador independente ────────► verify.md (APROVADO)
                               sdd goal NN ─────────────────────► GOAL PASS / GOAL FAIL
                                      │
 "arquive a change NN" ───────► deltas viram a spec viva em capabilities/<cap>/spec.md
                               pasta inteira (com origem/) → concluidas/NN-slug/
                               status: Done
```

## 2. Onde cada coisa fica

```text
 <specs>/
 ├── backlog/          ideias e itens em refinamento (NN - Tema.md)
 ├── changes/          changes em andamento
 │   └── NN-slug/
 │       ├── change.md         o quê, porquê, cenários, plano, tasks
 │       ├── origem/           o item do backlog que gerou a change
 │       ├── evidence.jsonl    RED/GREEN gravados pelo motor (não editar)
 │       └── verify.md         veredito do verificador (não editar)
 ├── concluidas/       changes arquivadas (com a origem/ junto)
 ├── capabilities/     spec viva: o comportamento atual de cada capacidade
 │   └── _index.md     registro de capacidades e IDs SPEC-DOM-NNN
 └── _templates/       moldes de backlog, change e spec
```

Um item que gera várias changes fica na `origem/` da primeira; as seguintes
citam esse caminho.

## 3. O portão pelo chat (antes e depois da CHG-002)

```text
 HOJE                                         DEPOIS DA CHG-002
 ────                                         ─────────────────
 IA: sdd approve 01 P1                        você no chat: "aprovo P1 da change 01"
   └► motor: CLAUDECODE? → RECUSADO             │
                                                ▼
 você no terminal: sdd approve 01 P1          IA: sdd approve 01 P1 --frase "aprovo P1 da change 01"
   └► motor pede código XK7P                    │
   └► você digita → APROVADO                    ▼
                                              guard: "ask" → a ferramenta pede a sua permissão (clique)
                                                │
                                                ▼
                                              motor confere a frase:
                                                tem "aprov"? tem "P1"? tem "change 01"?
                                                ├─ não → RECUSADO, nada gravado
                                                └─ sim → status Approved
                                                         linha com via chat: "<sua frase>"

 Continua igual nos dois casos:
   • a IA escrever a aprovação direto no arquivo → edit_guard NEGA
   • linha de aprovação no formato antigo → continua aceita
```

A aprovação por frase é **honra, não imposto**: a máquina não prova que a
frase veio de você. Protegem o clique de permissão da ferramenta e a frase
citada no registro.

## 4. O que você diz em cada etapa

| Etapa | Você escreve no chat | A IA responde com |
|---|---|---|
| Ideia | o que quer, em texto livre | item no backlog e a sugestão de refinar |
| Refinar | "refine o item NN" | requisitos conferidos no código e perguntas |
| Pronto | "item NN Pronto" (depois de ler e editar) | confirmação e a sugestão de abrir a change |
| Abrir | "abra o item NN" | `change.md` em Draft e o que ler antes do P1 |
| P1 | "aprovo P1 da change NN" | plano, tasks e análise; o que ler antes do P2 |
| P2 | "aprovo P2 da change NN" | implementação cenário a cenário, com RED e GREEN |
| Fecho | "verifique a change NN" | veredito do verificador e `GOAL PASS`/`FAIL` |
| Archive | "arquive a change NN" | spec viva atualizada e a change em `concluidas/` |

Toda resposta da IA termina com o próximo passo.

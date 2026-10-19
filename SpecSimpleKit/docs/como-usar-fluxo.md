# Como usar o SpecSimpleKit: o fluxo

> Guia canônico para quem usa o kit pelo chat da IA (Claude Code, Antigravity).
> A regra que a IA segue está em `kernel/.agents/rules/sdd-fluxo.md`; este
> documento explica o mesmo fluxo para pessoas. Versão de 19/10/2026 (CHG-003).

---

## 0. Filosofia: SDD + TDD + BDD + XP pelo chat

O SpecSimpleKit foi desenhado para ser simples e fácil: **sem terminal**, operado **apenas pelo chat** com comandos em texto e permissões concedidas na própria ferramenta. É um framework guiado para quem não é desenvolvedor ou não tem conhecimento exato da metodologia, mantendo rigor técnico absoluto por baixo dos panos.

A base metodológica combina quatro pilares de engenharia:
- **SDD (Spec-Driven Development):** Nenhuma linha de código de produto é escrita sem antes formalizar a especificação viva do que deve ser feito e o porquê.
- **BDD (Behavior-Driven Development):** Requisitos são desdobrados em cenários comportamentais verificáveis no formato canônico `DADO / QUANDO / ENTÃO`, com tags estáveis de rastreabilidade (`SPEC-<DOM>-NNN/Cn`).
- **TDD (Test-Driven Development):** Todo comportamento novo ou modificado nasce de um teste que falha (`RED`), torna-se funcional com a implementação mínima (`GREEN`) e é lapidado com refatoração (`REFACTOR`). O motor do kit grava a evidência criptográfica de cada fase no `evidence.jsonl`.
- **XP (Extreme Programming):** Feedback rápido, baby steps (tarefas pequenas e atômicas), refatoração contínua sem medo e pair programming entre humano (decisão e aprovação) e IA (execução técnica e auditoria).

---

## 1. O Ciclo dos 4 Artefatos

O ciclo de vida de qualquer mudança no SpecSimpleKit se estrutura em **4 artefatos integrados e auditáveis**:

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 │ 1. CONSTITUTION (Regras Permanentes)                                   │
 │    Onde mora: AGENTS.md e .agents/rules/                               │
 │    O que é: limites inegociáveis, invariantes de segurança e           │
 │    anti-padrões do que a IA NÃO PODE fazer. Imutável pela IA.          │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │ governa
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │ 2. SPECIFICATION (O quê e Por quê)                                     │
 │    Onde mora: change.md (seções Por quê, Deltas e Cenários BDD)        │
 │    O que é: descrição funcional sem amarras a stack; critérios         │
 │    observáveis em cenários DADO/QUANDO/ENTÃO. Aprovada no Portão P1.   │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │ orienta
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │ 3. TECHNICAL PLAN (Como)                                               │
 │    Onde mora: change.md (seções Decisões, Contratos, Invariantes,      │
 │    Impact e Análise pré-implementação)                                 │
 │    O que é: arquitetura, riscos, arquivos tocados e dependências.      │
 │    Aprovado no Portão P2.                                              │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │ decompõe
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │ 4. TASKS (Tarefas Atômicas e Verificáveis)                             │
 │    Onde mora: change.md (seção Tasks)                                  │
 │    O que é: lista estrita de passos RED/GREEN/REFACTOR vinculados a     │
 │    cada cenário SPEC-<DOM>-NNN/Cn. Executadas no loop autônomo.        │
 └────────────────────────────────────────────────────────────────────────┘
```

A Constitution é perene e vive no repositório. Os outros 3 artefatos (Specification, Technical Plan e Tasks) residem de forma unificada e versionada dentro de cada `change.md`, sob governança estrita de aprovações humanas.

---

## 2. O Loop Autônomo e as Salvaguardas

Após a aprovação do **Portão P2**, a IA assume a execução em **loop autônomo**:
1. Implementa suíte por suíte ou alvo por alvo;
2. Roda `sdd test <alvo>` para registrar o `RED` (falha comprovada);
3. Escreve a implementação mínima e roda `sdd test <alvo>` para registrar o `GREEN` (sucesso);
4. Aplica refatoração (`REFACTOR`) e revalida;
5. Executa a suíte completa com `sdd validate`.

### Salvaguardas do Loop
- **Limite de 3 falhas:** Se o mesmo critério falhar 3 vezes consecutivas, a IA interrompe o loop imediatamente e devolve o controle ao usuário com o diagnóstico claro.
- **Teto de turnos:** Execuções contínuas respeitam limites de turnos e contexto para evitar loops infinitos.
- **Verificador Independente:** Quem implementou a change NÃO declara que ela está pronta. O fecho exige que a skill de auditoria (`sdd-verify`) execute em contexto limpo, confira mutações e emita o veredito formal `verify.md`.

---

## 3. O Fluxo de Trabalho (Do pedido ao código pronto)

Limites por change: 1 capacidade, 2 requisitos, 8 cenários, 10 arquivos fonte/teste do produto e 250 linhas em `change.md`. Acima de qualquer limite, divida em changes encadeadas antes do P1.

```text
 VOCÊ (apenas pelo chat)              IA                              MOTOR / GUARD
 ───────────────────────              ──                              ─────────────
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
                               registra os IDs SPEC-DOM-NNN no _index.md
                                      │
                         ┌────────────┴────────────┐
                         │ Etapa 1  Especificação  │  Por quê + cenários DADO/QUANDO/ENTÃO
                         │ Etapa 2  Clarificação   │  "Perguntas em aberto" vazia
                         └────────────┬────────────┘
                                      │
 ╔════════════ P1: Especificação e Escopo ═╗
 ║ você no chat: "aprovo P1   ║ ─────┼──────────────────────────► sdd approve NN P1 --frase
 ║  da change NN"             ║      │                              status: Approved
 ╚════════════════════════════╝      │
                         ┌────────────┴────────────┐
                         │ Etapa 3  Plano + Tasks  │  Decisões, contratos, impact, tasks agrupadas
                         │ Etapa 4  Análise        │  cobertura e escopo da change inteira
                         └────────────┬────────────┘
 ╔════════════ P2: Plano Técnico e Tasks ══╗
 ║ "aprovo P2 da change NN"   ║ ─────┼──────────────────────────► sdd approve NN P2 --frase
 ╚════════════════════════════╝      │                              status: In-Implementation
                                      │                              base_ref = HEAD
                         ┌────────────┴────────────┐
                         │ LOOP AUTÔNOMO PÓS-P2    │
                         │  por suíte/alvo:        │
                         │   suíte completa ──────┼──► sdd test <alvo>  → RED (falha)
                         │   implementação ───────┼──► sdd test <alvo>  → GREEN (passou)
                         │   refatora              │       tags C1..Cn; goal agrega a change
                         └────────────┬────────────┘
                                      │
                               sdd validate (gates completos) ──► last-full.json
                               verificador independente ────────► verify.md (APROVADO)
                               sdd goal NN ─────────────────────► GOAL PASS da change inteira
                                      │
 "arquive a change NN" ───────► deltas viram spec viva em capabilities/<cap>/spec.md
                               pasta inteira (com origem/) → concluidas/NN-slug/
                               status: Done ➔ sugere comando git commit
```

---

## 4. Onde cada coisa fica

```text
 <specs>/
 ├── backlog/          ideias e itens em refinamento (NN - Tema.md)
 ├── changes/          changes em andamento
 │   └── NN-slug/
 │       ├── change.md         o quê, porquê, cenários, plano, tasks
 │       ├── origem/           o item do backlog que gerou a change
 │       ├── evidence.jsonl    RED/GREEN gravados pelo motor (não editar)
 │       └── verify.md         veredito do verificador independente (não editar)
 ├── concluidas/       changes arquivadas (com a pasta origem/ junto)
 ├── capabilities/     spec viva: o comportamento atual de cada capacidade
 │   └── _index.md     registro de capacidades e IDs SPEC-DOM-NNN
 └── _templates/       moldes de backlog, change e spec
```

---

## 5. Guia Conversacional: O que você diz em cada etapa

Você **não precisa usar o terminal**. Todas as ações são disparadas por frases naturais no chat:

| Etapa | Você escreve no chat | A IA executa | Validação pelo motor / guard |
|---|---|---|---|
| **Ideia** | Descreva o que precisa em texto livre | Cria o item em `backlog/NN - Tema.md` com `Prontidão: Levantamento` | Verifica existência de templates |
| **Refinar** | `"refine o item NN"` | Roda a skill `backlog-refinement`: checa código atual, levanta RF/RN e faz perguntas | Não altera código de produto |
| **Pronto** | `"item NN Pronto"` (após ler e ajustar) | Registra `Prontidão: Pronto` | Só o usuário pode definir Pronto |
| **Abrir** | `"abra o item NN"` | Cria `change.md` em `Draft` e move o item para `origem/` | `sdd spec-lint` valida estrutura |
| **P0 (se houver)** | `"aprovo P0 da change NN"` | Valida o tema macro da change | `sdd approve NN P0 --frase` |
| **Portão P1** | `"aprovo P1 da change NN"` | Homologa a Especificação e cenários BDD; move para `Approved` | `sdd approve NN P1 --frase` valida frase e zera dúvidas |
| **Portão P2** | `"aprovo P2 da change NN"` | Homologa Plano Técnico, Impact e Tasks; move para `In-Implementation` | `sdd approve NN P2 --frase` grava `base_ref` |
| **Loop TDD** | *(Autônomo)* | Executa tarefas RED ➔ GREEN ➔ REFACTOR | `sdd test <alvo>` grava evidências reais |
| **Fecho** | `"verifique a change NN"` | Roda `sdd validate`, aciona subagente `sdd-verify` e confere `sdd goal NN` | `sdd goal` audita 9 dimensões de integridade |
| **Archive** | `"arquive a change NN"` | Promove deltas para `capabilities/`, move para `concluidas/` e sugere commit pronto | `sdd archive NN` |

Toda resposta da IA termina indicando claramente o próximo passo do fluxo.

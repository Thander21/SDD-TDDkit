# SDD-TDDkit

**A oficina onde o SpecSimpleKit é construído.**

> Quer **usar** o kit num projeto seu? Vá direto para o repositório do produto:
> **[SpecSimpleKit](https://github.com/Thander21/SpecSimpleKit)**
> — repositório independente pronto para clonar (`git clone --depth 1 https://github.com/Thander21/SpecSimpleKit.git SpecSimpleKit`),
> com instruções de instalação e uso guiado pelo chat.

## O que é

O [SpecSimpleKit](https://github.com/Thander21/SpecSimpleKit) é um mini-framework que guia a IA
(Claude Code, Antigravity) a trabalhar com **SDD** (Spec-Driven Development:
spec com cenários antes do código) e **TDD** (Test-Driven Development: teste
que falha antes do código que o faz passar), com portões que só o usuário
aprova.

O kit estrutura todo o desenvolvimento no **Ciclo dos 4 Artefatos**:
1. **Constitution:** Regras invariantes e limites permanentes (`AGENTS.md` e `.agents/rules/`);
2. **Specification:** O que e por quê com cenários BDD `DADO/QUANDO/ENTÃO` (`change.md`);
3. **Technical Plan:** Arquitetura, riscos, impacto e decisões técnicas (`change.md`);
4. **Tasks:** Tarefas atômicas de RED/GREEN/REFACTOR rastreáveis (`change.md`).

Para entender o fluxo completo, consulte o guia canônico:
👉 **[`SpecSimpleKit/docs/como-usar-fluxo.md`](SpecSimpleKit/docs/como-usar-fluxo.md)**.

Este repositório é onde o kit é desenvolvido, **usando o próprio kit**
(dogfooding): a raiz é um projeto SDD com o SpecSimpleKit instalado, e cada
melhoria do kit passa pelo mesmo caminho que ele ensina — backlog, change com
cenários, aprovação no chat, testes RED e GREEN, verificação independente e
archive. Se o kit falha aqui, a falha vira item de backlog e é corrigida aqui.

## O que ele faz

- Guarda o **produto** em `SpecSimpleKit/` (que é sincronizado com o repositório
  [Thander21/SpecSimpleKit](https://github.com/Thander21/SpecSimpleKit) para uso nos projetos).
- Guarda o **desenvolvimento** do produto na raiz: as specs do próprio kit
  (`docs/Specs/`), as regras de IA instaladas e a suíte de testes.
- Prova cada mudança com a suíte do kit no Windows PowerShell 5.1 e no pwsh 7
  antes de qualquer commit (pre-commit com `sdd validate`).

## Para quem

Para quem desenvolve o SpecSimpleKit. Para usar o kit em outros projetos, veja o
[repositório do SpecSimpleKit](https://github.com/Thander21/SpecSimpleKit).

## Estrutura

```text
SDD-TDDkit/
├── SpecSimpleKit/          o produto (vai para os projetos)
│   ├── README.md           como usar
│   ├── install.ps1         instala, confere e atualiza o kit num projeto
│   ├── kernel/             FONTE das regras, skills, moldes e do motor
│   ├── profiles/           perfis de stack
│   ├── machine/            guards de comando e de edição
│   ├── tests/              suíte do kit (5.1 e 7; só roda aqui)
│   └── docs/, CHANGELOG.md, INBOX.md, VERSION, Metodologia SDD.ai
├── AGENTS.md, .claude/, .agents/, tools/sdd/, .sdd/
│                           kit instalado na raiz (CÓPIAS do kernel + perfil powershell)
└── docs/
    ├── Specs/              backlog, changes, concluidas e capabilities do próprio kit
    └── diagnostico-comparativo.html
```

## Como desenvolver

- **Pelo chat:** abra o repositório no Claude Code ou no Antigravity; o
  `AGENTS.md` guia a IA. Peça "refine o item NN", aprove com "aprovo P1 da
  change NN" e assim por diante (guia em
  [`SpecSimpleKit/docs/como-usar-fluxo.md`](SpecSimpleKit/docs/como-usar-fluxo.md)).
- **Fonte e cópia:** edite sempre em `SpecSimpleKit/kernel/`; os arquivos do
  kit na raiz são cópias. Depois de provar com os testes, sincronize:
  `powershell -File SpecSimpleKit/install.ps1 update -Destino .` (com change
  em implementação, `-Forcar`, dito no relato).
- **Fecho automático:** com o `GOAL PASS`, a IA faz revisão, simplificação,
  segurança e learn (pelos comandos da IDE ou relendo o diff), arquiva e para
  no commit, que é seu.

| Momento | Comando |
|---|---|
| Depois de alterar (~5 s) | `powershell -File tools/sdd/sdd.ps1 check` |
| Antes de commit (suíte completa, ~7 min) | `powershell -File tools/sdd/sdd.ps1 validate` |
| RED e GREEN | `powershell -File tools/sdd/sdd.ps1 test tests/<arquivo>.ps1 --change NN` |
| Parada da change | `powershell -File tools/sdd/sdd.ps1 goal NN` |
| Suíte direto | `powershell -File tests/run_all.ps1 [-Py <python do venv>]` |
| Publicar o kit no repo público | `powershell -File tools/push-kit.ps1` (ou `git subtree push --prefix=SpecSimpleKit specsimplekit main`) |

## Fluxo e Matriz de Skills

| Fase / Portão | O que acontece | Qual Skill / Ferramenta roda | Ação do Usuário |
|---|---|---|---|
| **0. Setup Inicial** | Detecta a stack, cria `.sdd/profile.json` e configura `AGENTS.md` | `sdd-bootstrap` | Pede no chat: "Instale o SpecSimpleKit" |
| **1. Backlog & Ideação** | Levanta requisitos no código, cria cenários e refina o item | `backlog-refinement` | Conversa, responde dúvidas e diz "Pronto" |
| **Portão P0 (Tema)** | Valida o tema macro e abre a change em `Draft` | `backlog-refinement` (modo abrir) | Escreve: "aprovo P0 da change NN" |
| **Portão P1 (Especificação)** | Formaliza os cenários BDD (`DADO/QUANDO/ENTÃO`) no `change.md` | IA autônoma (regras `sdd-fluxo`) | Escreve: "aprovo P1 da change NN" |
| **Plano & Decomposição** | Elabora a análise técnica e gera o arquivo separado `tasks.md` | IA autônoma (regras `sdd-fluxo`) | Revisa `change.md` e `tasks.md` |
| **Portão P2 (Change + Tasks)** | Homologa a arquitetura, impact e a lista de tarefas técnicas | Motor SDD (`sdd approve NN P2`) | Escreve: "aprovo P2 da change NN" |
| **Implementação Contínua** | Loop autônomo TDD contínuo: RED (falha) ➔ GREEN (passa) ➔ REFACTOR | Motor SDD (`sdd test <alvo> --change NN`) | Acompanha a execução contínua sem travas |
| **Verificação Independente** | Reexecuta testes, audita mutações e emite `verify.md` formal | `sdd-verify` (subagente auditor) | 100% autônomo (quem codificou não aprova) |
| **Fecho (GOAL PASS)** | Motor audita gates, integridade, árvore e evidências | Motor SDD (`sdd goal NN`) | Confirma o veredito |
| **Arquivamento & Commit** | Promove deltas para `capabilities/` e arquiva em `concluidas/` | Motor SDD (`sdd archive NN`) | Sugere comando e mensagem de commit prontos |

## Andamento

| Onde | O quê |
|---|---|
| `docs/Specs/concluidas/02-aprovacao-pelo-chat/` | CHG-002: portões aprovados por frase no chat (feito) |
| `docs/Specs/concluidas/05-guard-no-projeto/` | CHG-005: guard só no projeto, fim do passo `maquina` (feito) |
| `docs/Specs/changes/03-metodologia-guiada/` | CHG-003: metodologia documentada e guiada (em implementação) |
| `docs/Specs/changes/01-instalador-modo-agente/` | CHG-001: instalador em modo agente (Draft; será revista no modo pasta) |
| `docs/Specs/backlog/` | 04 perfil powershell, 06 ideias do PDV D+, 07 endurecer a frase |

Specs vivas criadas:
- [`docs/Specs/capabilities/motor/spec.md`](docs/Specs/capabilities/motor/spec.md)
- [`docs/Specs/capabilities/guard/spec.md`](docs/Specs/capabilities/guard/spec.md)
- [`docs/Specs/capabilities/instalador/spec.md`](docs/Specs/capabilities/instalador/spec.md)
- [`docs/Specs/capabilities/fluxo/spec.md`](docs/Specs/capabilities/fluxo/spec.md)

## Regras de manutenção

1. Lição de método chega pelo `SpecSimpleKit/INBOX.md`; release no máximo
   uma vez por mês, com teste para cada mudança no motor.
2. Orçamento de tamanho: `sdd-core.md` até 5 KB, `sdd-fluxo.md` até 14 KB,
   Markdown gerenciado total até 45 KB (1 KB = 1024 bytes; decisão D9 da CHG-002, atualizado no item 04 para acomodar sdd-revisao.md).
3. Peça nova só com gatilho de dor medido (lista em `SpecSimpleKit/Metodologia SDD.ai`, §9).
4. Fonte dos scripts em ASCII e compatível com PowerShell 5.1 e 7.
5. Toda release atualiza `docs/diagnostico-comparativo.html` (versão, data,
   "O que o kit corrige", "Imposto ou honra", "Verificação", "Limites" e
   "Histórico") e republica no mesmo link:
   https://claude.ai/artifact/GCit5SpAwkbphRnXVsp6sB

Os identificadores técnicos continuam `sdd-kit` (marcadores
`sdd-kit:begin/end`, hooks `sdd-kit-guard`): mudá-los quebraria os projetos
já instalados.

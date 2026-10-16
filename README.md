# SDD-TDDkit

Repositório de **desenvolvimento** do SpecSimpleKit. Aqui o próprio kit é
construído com o método que ele ensina (dogfooding): a raiz é um projeto SDD
com o SpecSimpleKit instalado, e cada melhoria passa por backlog, change,
portões, TDD e verificação independente.

**O produto está em [`SpecSimpleKit/`](SpecSimpleKit/README.md)** — leia o
README de lá para instalar e usar num projeto:
https://github.com/Thander21/SDD-TDDkit/tree/main/SpecSimpleKit

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
| RED e GREEN | `powershell -File tools/sdd/sdd.ps1 test SpecSimpleKit/tests/<arquivo>.ps1 --change NN` |
| Parada da change | `powershell -File tools/sdd/sdd.ps1 goal NN` |
| Suíte direto | `powershell -File SpecSimpleKit/tests/run_all.ps1 [-Py <python do venv>]` |

## Andamento

| Onde | O quê |
|---|---|
| `docs/Specs/concluidas/02-aprovacao-pelo-chat/` | CHG-002: portões aprovados por frase no chat (feito) |
| `docs/Specs/changes/05-guard-no-projeto/` | CHG-005: guard só no projeto, fim do passo `maquina` (Draft, próxima) |
| `docs/Specs/changes/01-instalador-modo-agente/` | CHG-001: instalador em modo agente (Draft; será revista no modo pasta) |
| `docs/Specs/backlog/` | 03 metodologia documentada, 04 perfil powershell, 06 ideias do PDV D+, 07 endurecer a frase |

Spec viva já criada: [`docs/Specs/capabilities/motor/spec.md`](docs/Specs/capabilities/motor/spec.md).

## Regras de manutenção

1. Lição de método chega pelo `SpecSimpleKit/INBOX.md`; release no máximo
   uma vez por mês, com teste para cada mudança no motor.
2. Orçamento de tamanho: `sdd-core.md` até 5 KB, `sdd-fluxo.md` até 14 KB,
   Markdown gerenciado total até 40 KB (1 KB = 1024 bytes; decisão D9 da CHG-002).
3. Peça nova só com gatilho de dor medido (lista em `SpecSimpleKit/Metodologia SDD.ai`, §9).
4. Fonte dos scripts em ASCII e compatível com PowerShell 5.1 e 7.
5. Toda release atualiza `docs/diagnostico-comparativo.html` (versão, data,
   "O que o kit corrige", "Imposto ou honra", "Verificação", "Limites" e
   "Histórico") e republica no mesmo link:
   https://claude.ai/artifact/GCit5SpAwkbphRnXVsp6sB

Os identificadores técnicos continuam `sdd-kit` (marcadores
`sdd-kit:begin/end`, hooks `sdd-kit-guard`): mudá-los quebraria os projetos
já instalados.

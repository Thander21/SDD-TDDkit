# Perfil powershell

> **Prontidão:** Pronto <!-- Levantamento | Requisitos | Pronto | Adiado | Descartado -->
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

### Problema e valor

O perfil `powershell.json` (usado para dogfooding deste repositório e distribuído pelo kit para projetos PowerShell) opera atualmente com classificação de testes baseada apenas em exit code e padrões textuais (`relatorio: ""`), o que faz o `sdd goal` anotar aviso de confiança reduzida ("RED classificado só pelo exit code").

Além disso, a suíte completa de testes do kit leva cerca de 8 minutos, tornando `commit_gate: full` muito oneroso no fluxo frequente de commits e ampliando a janela de concorrência onde qualquer alteração na árvore resulta em `validate` `INSTAVEL`.

Por fim, o gate `light` não audita automaticamente o orçamento de tamanho do Markdown gerenciado (`README.md`, Regras de manutenção 2), permitindo que adições ao kernel (como `sdd-revisao.md`) ultrapassem o limite normatizado sem aviso em tempo de `check`.

Refinar o perfil e os scripts de apoio eleva a confiança de evidências de teste a estruturada (`junit`), automatiza as regras de manutenção do repositório e permite calibrar a velocidade do ciclo de commit.

### Estado atual no código

| Item do levantamento | Existe hoje? | Evidência |
|---|---|---|
| `powershell.json` rascunho vs `.sdd/profile.json` | Sim | `SpecSimpleKit/profiles/powershell.json:1-58` (`calibrado: false`, `relatorio: ""`, `commit_gate: "full"`); cópia local em `.sdd/profile.json:1-58` (`calibrado: true`). |
| Sem relatório estruturado / proposta JUnit | Parcial | O motor SDD já suporta leitura de relatórios JUnit (`SpecSimpleKit/kernel/tools/sdd/sdd.ps1:648-674`), mas `tests/helpers.ps1:88-92` só exibe resumo em texto via stdout e sai com exit code; `powershell.json:32` mantém `relatorio: ""`. |
| Gate `full` / tempo de commit / `commit_gate` | Sim | `commit_gate: "full"` em `.sdd/profile.json:6` e `SpecSimpleKit/profiles/powershell.json:6`; `tools/sdd/sdd.ps1:1174` honra essa chave executando `run_all.ps1` a cada commit. |
| Gate `light` e orçamento de Markdown | Parcial | `README.md:124-125` define limite de 5 KB (`sdd-core.md`), 14 KB (`sdd-fluxo.md`) e 40 KB total. Mas os gates em `SpecSimpleKit/profiles/powershell.json:20-23` e `.sdd/profile.json:20-23` só testam sintaxe .ps1 e caracteres ASCII. Medição atual do kernel: `sdd-core.md` = 5.067 B, `sdd-fluxo.md` = 12.495 B, total Markdown = 42.895 B (excede 40.960 B devido a regras adicionadas recentemente). |
| Caminho da suíte `tests/run_all.ps1` | Já resolvido | A suíte está na raiz em `tests/run_all.ps1` (a pasta `SpecSimpleKit/tests/` não existe). Ambos `.sdd/profile.json:26` e `SpecSimpleKit/profiles/powershell.json:26` já usam `tests/run_all.ps1`. |
| `validate` resultando em `INSTAVEL` | Sim | `tools/sdd/sdd.ps1:573, 579` descarta e marca `INSTAVEL` se a árvore `write-tree` calculada por `Get-SddArvore` (`tools/sdd/sdd.ps1:210-230`) mudar entre o início e o fim da execução. |

### Requisitos funcionais

- **RF1:** O gate `light` deste repositório DEVE verificar se os arquivos Markdown do kernel respeitam os orçamentos: `sdd-core.md` ≤ 5 KB (5.120 bytes), `sdd-fluxo.md` ≤ 14 KB (14.336 bytes) e total do kernel ≤ teto normatizado.
- **RF2:** A Regra de manutenção 2 em `README.md` DEVE ser reconciliada formalmente para atualizar o teto total do kernel (de 40 KB para 45 KB / 46.080 bytes) acomodando a inclusão de `sdd-revisao.md`.
- **RF3:** Um teste automatizado no kit DEVE garantir que o gate `light` falha se qualquer um dos arquivos ou o total ultrapassar o orçamento estabelecido.

### Regras de negócio e restrições

- **RN1:** Compatibilidade de interpretadores: o comando do gate em `profile.json` e eventuais scripts de validação devem rodar em Windows PowerShell 5.1 e pwsh 7 (`README.md`, Regras de manutenção 4).
- **RN2:** Fonte em ASCII estrito para todos os scripts `.ps1` e `.cmd` (`README.md`, Regras de manutenção 4; gate `light`).
- **RN3:** Respeito aos limites do Markdown gerenciado: 1 KB = 1024 bytes (decisão D9 da CHG-002); qualquer alteração de limite deve ser registrada no `README.md`.

### Fora de escopo

- Emissão de relatório JUnit em `tests/helpers.ps1` e alteração de `test.relatorio` no `powershell.json` (desmembrado para U2 em backlog separado).
- Calibração de `commit_gate: light` vs `full` no dogfooding (desmembrado para U3).
- Alteração no parser de relatórios em `SpecSimpleKit/kernel/tools/sdd/sdd.ps1`.

### Recorte proposto

| Unidade | Nível | Capacidade | `risk` | Depende de |
|---|---|---|---|---|
| **U1: Orçamento de Markdown no gate `light`** | Pequeno | `fluxo` / `perfis` | — | — |

*Nota de desmembramento:* U2 (Relatório JUnit no `helpers.ps1` e perfil `powershell`, nível Feature) e U3 (`commit_gate` no dogfooding, nível Trivial) foram retirados deste item para execução independente posterior.

### Perguntas para o usuário

1. O item do backlog reúne 3 unidades de escopos distintos (U1: gate de orçamento de Markdown, U2: JUnit no helpers + perfil powershell, U3: commit_gate light vs full). Recomendamos desmembrar e tratar a **Unidade 1 (Pequeno)** ou a **Unidade 2 (Feature)** como primeira entrega independente. Qual frente você deseja priorizar para execução?

### Respostas

| # | Resposta | Data |
|---|---|---|
| 1 | Priorizar a Unidade 1 (Pequeno: orçamento de Markdown no gate light e reconciliação da regra). | 19/10/2026 |

## Tasks

- [x] RED (C4): tests/test_fluxo_metodologia.ps1 -> Falha esperada: Orcamento de Markdown no gate light
- [x] GREEN (C4): tests/test_fluxo_metodologia.ps1 -> passou
- [x] REFACTOR: sdd check e sdd validate verdes com o novo gate ativo

## Encaminhamento

Pronto em 19/10/2026. Nível Pequeno (U1: orçamento de Markdown no gate light); tasks definidas na seção Tasks deste item. As unidades U2 (JUnit no helpers + perfil powershell) e U3 (commit_gate light vs full) foram desmembradas para itens posteriores.

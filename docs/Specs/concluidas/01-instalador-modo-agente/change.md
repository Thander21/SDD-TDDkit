---
id: CHG-001
title: Modo Pasta Autocontido (Zero Residuo, testes fora do produto, start e remocao pelo chat)
status: Done
capabilities: [instalador]
risk: [start-chat, config-global, arquivo-do-usuario]
fonte_normativa:
base_ref: 8d1832f0cc937c93a48d8650b40788d972acbe96
impact:
  modified_files: [SpecSimpleKit/install.ps1, SpecSimpleKit/instalar.cmd, SpecSimpleKit/README.md, README.md, SpecSimpleKit/CHANGELOG.md, SpecSimpleKit/INBOX.md, .sdd/profile.json, tools/sdd/sdd.ps1, SpecSimpleKit/kernel/tools/sdd/sdd.ps1, SpecSimpleKit/kernel/.agents/rules/sdd-fluxo.md, .agents/rules/sdd-fluxo.md, SpecSimpleKit/docs/como-usar-fluxo.md, "tests/**", spec_driven_development.md]
  new_files: [tests/test_install_modo_pasta.ps1, tools/push-kit.ps1, docs/spec_driven_development.md, docs/Specs/changes/01-instalador-modo-agente/tasks.md]
---

# CHG-001 — Modo Pasta Autocontido (Zero Resíduo)

> **Origem:** `origem/01 - Start pelo chat.md` (movido do backlog). **Regra:** `.agents/rules/sdd-fluxo.md`.

## Por quê

O kit deve ser consumido como uma pasta autocontida (`SpecSimpleKit/`), clonada ou copiada para dentro do projeto do usuário. O modelo legado que copiava dezenas de arquivos gerenciados para a raiz do usuário (`.agents/rules/`, `tools/sdd/`, etc.) e deixava a suíte de testes interna do framework (`SpecSimpleKit/tests/`) dentro do produto gera poluição, atrito na atualização e dificuldade na remoção.

Com o Modo Pasta Autocontido:
1. Os testes do próprio kit (`tests/`) moram na oficina (`SDD-TDDkit/tests/`), fora da pasta do produto `SpecSimpleKit/`.
2. A instalação e inicialização ocorrem 100% pelo chat: a IA detecta a pasta, configura o bloco no `AGENTS.md` apontando para o kit e calibra o perfil sem copiar arquivos para a raiz.
3. A remoção apaga o bloco do `AGENTS.md` e deleta a pasta `SpecSimpleKit/`, deixando zero resíduo do framework.
4. A documentação viva (`Specs/` ou `Docs/Specs/`) é preservada intacta na raiz do projeto como patrimônio do usuário.

## Perguntas em aberto

<!-- Vazia = pronto para P0/P1. -->

## Decisões

| # | Decisão | Fonte (fala do usuário, regra, doc com data) | Data |
|---|---|---|---|
| D1 | A suíte de testes do kit (`tests/`) sai de `SpecSimpleKit/` e passa a morar na raiz da oficina `SDD-TDDkit/tests/`, garantindo que o produto distribuído fique limpo. | Instrução do usuário no chat | 19/10/2026 |
| D2 | Modo Pasta Autocontido: o kit roda autocontido dentro de `SpecSimpleKit/`. Nenhuma cópia de `.agents/rules/` ou `tools/sdd/` é despejada na raiz do usuário. | Decisão do usuário de zero resíduo | 19/10/2026 |
| D3 | Início conversacional: a IA lê o projeto, identifica a linguagem e edita o `AGENTS.md` inserindo o bloco do `sdd-kit` que instrui o uso direto de `SpecSimpleKit/`. | Decisão do usuário de fluxo guiado por chat | 19/10/2026 |
| D4 | Remoção em 1 comando: a pedido do usuário ("remova o kit"), a IA remove o bloco do `AGENTS.md` e apaga a pasta `SpecSimpleKit/`. | Instrução do usuário no chat | 19/10/2026 |
| D5 | A pasta `Specs/` (na raiz do projeto, ou `Docs/Specs/`) permanece como documentação viva desacoplada do framework, mantida mesmo após a remoção. | Instrução do usuário no chat | 19/10/2026 |

## Contratos

- `install.ps1 detectar -Destino <pasta>`: retorna JSON em uma linha com o estado do repositório, perfil detectado e se o kit está presente.
- Início pelo Chat: adiciona no `AGENTS.md` do usuário o bloco de regras apontando para `SpecSimpleKit/kernel/.agents/rules/sdd-core.md` e `sdd-fluxo.md`, criando o perfil em `.sdd/profile.json` dentro do projeto.
- Remoção pelo Chat: remove as linhas do bloco `sdd-kit` do `AGENTS.md` e deleta `SpecSimpleKit/`, preservando a pasta `Specs/`.
- Suíte do kit: os testes de desenvolvimento do produto rodam a partir de `tests/` na raiz do repositório de desenvolvimento.

## Invariantes

- `start-chat`: o início pelo chat funciona sem rodar instalador à mão; a IA
  sabe o estado da pasta antes de perguntar.
- `config-global`: nada fora do projeto muda sem comando explícito do
  humano e plano mostrado antes.
- `arquivo-do-usuario`: instalador e remoção nunca sobrescrevem nem apagam
  arquivo do projeto fora dos gerenciados; arquivo gerenciado editado é
  preservado e listado.

## Deltas — capacidade `instalador`

### ADDED Requirements

#### Requirement: SPEC-INST-001 — Detectar o estado da pasta

O sistema DEVE informar, sem gravar nada, o estado da pasta do projeto em
uma linha JSON.

##### Scenario: C1 — Pasta sem o kit

- **DADO** um repositório git com `package.json` e sem a pasta `SpecSimpleKit/`
- **QUANDO** a IA roda `install.ps1 detectar -Destino <pasta>`
- **ENTÃO** a saída tem `kit_instalado: false`, `git: true` e `perfil_sugerido: "node"`, e a árvore git continua igual

##### Scenario: C2 — Pasta com o kit em modo pasta

- **DADO** um repositório com a pasta `SpecSimpleKit/` presente e referenciada no `AGENTS.md`
- **QUANDO** a IA roda `detectar`
- **ENTÃO** a saída tem `kit_instalado: true`, `modo: "pasta"`, `perfil: "node"` e `kit_versao`

##### Scenario: C3 — Pasta sem git

- **DADO** uma pasta que não é repositório git
- **QUANDO** a IA roda `detectar`
- **ENTÃO** a saída tem `git: false`, exit 0, e nenhum `git init` é feito

#### Requirement: SPEC-INST-002 — Modo Pasta Autocontido (Zero Resíduo)

O sistema DEVE configurar o projeto apontando diretamente para `SpecSimpleKit/` sem copiar regras ou motor para a raiz do usuário.

##### Scenario: C1 — Início no projeto sem cópias na raiz

- **DADO** um repositório com `SpecSimpleKit/` clonado
- **QUANDO** a IA configura o modo pasta
- **ENTÃO** o `AGENTS.md` recebe o bloco referenciando `SpecSimpleKit/kernel/`, `.sdd/profile.json` é criado e nenhum arquivo de regras ou motor é copiado para a raiz do usuário

##### Scenario: C2 — Testes fora do produto

- **DADO** o produto `SpecSimpleKit/` preparado para distribuição
- **QUANDO** a pasta `SpecSimpleKit/` é inspecionada
- **ENTÃO** a suíte de testes do próprio framework reside em `tests/` na oficina e não dentro da pasta do produto `SpecSimpleKit/`

#### Requirement: SPEC-INST-003 — Remoção pelo Chat e preservação da documentação viva

O sistema DEVE remover o kit por completo a pedido do usuário, deixando zero resíduo do framework e preservando as especificações do usuário.

##### Scenario: C1 — Remoção completa via chat

- **DADO** um projeto com `SpecSimpleKit/` instalado em modo pasta e specs em `Specs/`
- **QUANDO** a IA executa a remoção
- **ENTÃO** o bloco do kit é removido do `AGENTS.md`, a pasta `SpecSimpleKit/` é deletada e a pasta `Specs/` continua intacta como documentação viva permanente

##### Scenario: C2 — Preservação de specs fora do kit

- **DADO** um projeto que gerou mudanças e capabilities em `Specs/`
- **QUANDO** o kit é removido
- **ENTÃO** as specs continuam legíveis e utilizáveis sem nenhuma ferramenta externa

### MODIFIED Requirements

### REMOVED Requirements

## Critérios de aceite

- Todos os cenários com teste rastreado (tag `SPEC-INST-NNN/Cn`) passando.
- `sdd validate` verde; `sdd goal 01` = `GOAL PASS`.
- A suíte existente (`test_install.ps1`) continua verde em 5.1 e 7.

## Análise pré-implementação

- **Unidade:** capacidade `instalador`; três requisitos e sete cenários no impacto.
- **Arquitetura:** a pasta `SpecSimpleKit/tests/` é transferida para `tests/` na raiz do `SDD-TDDkit` (a oficina). O produto `SpecSimpleKit/` passa a conter estritamente o código e as regras a serem consumidas nos projetos.
- **Modo Pasta Autocontido:** o `install.ps1` ganha a ação `detectar` (gera JSON com estado e stack) e suporte para ativar e desativar o modo pasta no `AGENTS.md` sem copiar arquivos de regras ou motor para a raiz do usuário.
- **Segurança e Risco:** a remoção pelo chat remove o bloco de regras e apaga a pasta `SpecSimpleKit/`, preservando a documentação viva `Specs/`.
- **Cobertura:** teste automatizado `tests/test_install_modo_pasta.ps1` cobrindo detecção, ativação do modo pasta, remoção limpa e integridade.

## Tasks

- [x] RED (C1,C2,C3): `tests/test_install_modo_pasta.ps1` -> Testar deteccao de pasta, modo pasta autocontido e remocao limpa
- [x] GREEN (C1,C2,C3): `tests/test_install_modo_pasta.ps1` -> Mover tests/ para raiz da oficina, implementar acao detectar e modo pasta no install.ps1
- [x] REFACTOR: Atualizar documentacao e READMEs | modo pasta operacional

### Pós-GOAL

- [ ] Archive (a pedido do usuário): deltas na spec viva, `git mv` para `concluidas/`, `status: Done`

## Exceções

## Aprovações

<!-- Gravado só pelo 'sdd approve NN P1|P2' no terminal do usuário. -->
- P0: aprovado por Thander em 2026-10-19 00:35 (sdd approve; via chat: "aprovo P0 da change 01"; change.md antes: 784ae5abf17d)
- P1: aprovado por Thander em 2026-10-19 00:36 (sdd approve; via chat: "aprovo P1 da change 01"; change.md antes: c61486e34ef9)
- P2: aprovado por Thander em 2026-10-19 00:38 (sdd approve; via chat: "aprovo P2 da change 01"; change.md antes: b465a05072da)

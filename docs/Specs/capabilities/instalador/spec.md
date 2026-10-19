# instalador

> **Domínio:** `INST` · **Origem no código:** `SpecSimpleKit/install.ps1`, `SpecSimpleKit/instalar.cmd`, `SpecSimpleKit/project-templates/`.
> Este arquivo descreve o comportamento **atual**. Só muda no archive de uma
> change, pelos deltas dela. Cabeçalhos no formato do OpenSpec (Purpose,
> Requirements, Requirement, Scenario) para a validação externa continuar possível.

## Purpose

Instalação, detecção, inicialização e remoção do SpecSimpleKit em projetos de qualquer stack, permitindo o consumo do kit como pasta autocontida e sem resíduo na raiz.

## Requirements

### Requirement: SPEC-INST-001 — Detectar o estado da pasta

O sistema DEVE informar, sem gravar nada, o estado da pasta do projeto em
uma linha JSON.

#### Scenario: C1 — Pasta sem o kit

- **DADO** um repositório git com `package.json` e sem a pasta `SpecSimpleKit/`
- **QUANDO** a IA roda `install.ps1 detectar -Destino <pasta>`
- **ENTÃO** a saída tem `kit_instalado: false`, `git: true` e `perfil_sugerido: "node"`, e a árvore git continua igual

#### Scenario: C2 — Pasta com o kit em modo pasta

- **DADO** um repositório com a pasta `SpecSimpleKit/` presente e referenciada no `AGENTS.md`
- **QUANDO** a IA roda `detectar`
- **ENTÃO** a saída tem `kit_instalado: true`, `modo: "pasta"`, `perfil: "node"` e `kit_versao`

#### Scenario: C3 — Pasta sem git

- **DADO** uma pasta que não é repositório git
- **QUANDO** a IA roda `detectar`
- **ENTÃO** a saída tem `git: false`, exit 0, e nenhum `git init` é feito

> Contrato: `install.ps1 detectar -Destino <pasta>` -> JSON em uma linha com propriedades `kit_instalado`, `git`, `perfil_sugerido` / `perfil`, `modo`.
> Testes: `tests/test_install_modo_pasta.ps1` (tags `SPEC-INST-001/C1..C3`).

### Requirement: SPEC-INST-002 — Modo Pasta Autocontido (Zero Resíduo)

O sistema DEVE configurar o projeto apontando diretamente para `SpecSimpleKit/` sem copiar regras ou motor para a raiz do usuário.

#### Scenario: C1 — Início no projeto sem cópias na raiz

- **DADO** um repositório com `SpecSimpleKit/` clonado
- **QUANDO** a IA configura o modo pasta
- **ENTÃO** o `AGENTS.md` recebe o bloco referenciando `SpecSimpleKit/kernel/`, `.sdd/profile.json` é criado e nenhum arquivo de regras ou motor é copiado para a raiz do usuário

#### Scenario: C2 — Testes fora do produto

- **DADO** o produto `SpecSimpleKit/` preparado para distribuição
- **QUANDO** a pasta `SpecSimpleKit/` é inspecionada
- **ENTÃO** a suíte de testes do próprio framework reside em `tests/` na oficina e não dentro da pasta do produto `SpecSimpleKit/`

> Contrato: Início conversacional sem cópias para a raiz do projeto; pasta de testes na raiz da oficina.
> Testes: `tests/test_install_modo_pasta.ps1` (tags `SPEC-INST-002/C1..C2`).

### Requirement: SPEC-INST-003 — Remoção pelo Chat e preservação da documentação viva

O sistema DEVE remover o kit por completo a pedido do usuário, deixando zero resíduo do framework e preservando as especificações do usuário.

#### Scenario: C1 — Remoção completa via chat

- **DADO** um projeto com `SpecSimpleKit/` instalado em modo pasta e specs em `Specs/`
- **QUANDO** a IA executa a remoção
- **ENTÃO** o bloco do kit é removido do `AGENTS.md`, a pasta `SpecSimpleKit/` é deletada e a pasta `Specs/` continua intacta como documentação viva permanente

#### Scenario: C2 — Preservação de specs fora do kit

- **DADO** um projeto que gerou mudanças e capabilities em `Specs/`
- **QUANDO** o kit é removido
- **ENTÃO** as specs continuam legíveis e utilizáveis sem nenhuma ferramenta externa

> Contrato: Remoção do bloco no `AGENTS.md` e deleção da pasta `SpecSimpleKit/`, mantendo `Specs/`.
> Testes: `tests/test_install_modo_pasta.ps1` (tags `SPEC-INST-003/C1..C2`).

## Requisitos removidos

| ID | Change | Motivo |
|---|---|---|

## Histórico

| Change | Data | Efeito |
|---|---|---|
| CHG-001 | 2026-10-19 | Criação da spec com SPEC-INST-001, SPEC-INST-002 e SPEC-INST-003 (Modo Pasta Autocontido) |

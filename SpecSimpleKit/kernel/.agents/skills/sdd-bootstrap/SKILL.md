---
name: sdd-bootstrap
description: "Instancia o kit SDD num projeto já instalado pelo install.ps1: descobre a stack e as convenções no código, faz no máximo 5 perguntas, preenche só a seção do projeto no AGENTS.md e calibra o perfil de gates com sondas. Use logo depois de instalar o kit, ao trocar de stack ou para recalibrar o perfil. Não use para criar regras de domínio especulativas."
---

# Bootstrap do kit SDD no projeto

Pré-requisito: o usuário rodou `install.ps1 projeto -Destino <repo> -Perfil
<stack>` a partir do repositório do kit. Você trabalha **dentro** do projeto.
Não reescreva os arquivos gerenciados pelo kit (`.sdd/kit.lock.json` lista).

## 1. Descobrir (só leitura)

- Stack pela ordem de detecção: unity (`ProjectSettings/ProjectVersion.txt`)
  > unreal (`*.uproject`) > flutter (`pubspec.yaml` com sdk flutter) > rust
  (`Cargo.toml`) > dotnet (`*.sln`, `*.csproj`) > node (`package.json`) >
  python (`pyproject.toml`, `requirements*.txt`). Repositório misto: anote
  cada parte e a pasta dela.
- Comandos que existem de verdade (scripts do `package.json`, `Makefile`,
  CI em `.github/workflows`, README), pastas de teste, convenções de nome,
  camadas e o que já está no `.gitignore`.
- Cada fato com `arquivo:linha`. Não invente camada, regra nem invariante.

## 2. Perguntar (no máximo 5, uma por vez, com recomendação)

1. O que é o projeto, em uma linha, e quem o usa.
2. Quais riscos promovem trabalho a feature (ex.: dados de usuário, dinheiro,
   save do jogo, protocolo de rede, norma regulatória) e se algum exige
   fonte normativa. Viram tags em `projeto.riscos` e `projeto.riscos_com_fonte`.
3. Nível do commit-gate: `full` (padrão) ou `light` (stacks caras, como
   Unity e Unreal), com o tempo medido em mãos.
4. Idioma do projeto (respostas, commits, comentários).
5. Se o projeto já tem testes rodando por linha de comando e qual é o alvo
   de um teste (arquivo, filtro ou nome).

## 3. Preencher

- Só a seção do projeto no `AGENTS.md` (fora dos marcadores do kit): o que é,
  stack e pastas, comandos reais, convenções observadas e a tabela de Riscos
  (tag → invariantes → cenário obrigatório), tudo citando a fonte.
  Invariante sem incidente ou norma por trás fica como "hipótese".
- `.sdd/profile.json`: comandos que de fato rodam, `projeto.riscos`,
  `commit_gate`. Caminho de máquina (editor, venv) vai em
  `.sdd/profile.local.json` (`vars`), fora do Git.
- `<specs>/capabilities/_index.md`: liste as capacidades que o código já tem,
  sem escrever spec viva do legado.
- **Não crie** regras de domínio nem personas agora: elas nascem pelo
  `learn` quando juntar 3 armadilhas do mesmo território.

## 4. Calibrar

1. `sdd check` e `sdd validate` numa árvore limpa. Vermelho de legado:
   quarentena documentada (skip nativo + item de backlog) ou correção, com o
   usuário; nunca afrouxe o gate em silêncio.
2. As 3 sondas da seção `calibracao` do perfil: `sdd test <alvo> --sonda
   carga|red|zero`. Apague os arquivos de sonda depois.
3. `sdd calibrate`: só marca `calibrado: true` com as sondas certas e os
   dois gates verdes; registra os tempos.
4. `sdd install-hook` (pre-commit).

## 5. Fechar

- Liste o que gerou, com a fonte de cada fato, e o que ficou como hipótese.
- O usuário revisa o diff e faz o commit do bootstrap.
- Primeiro projeto de uma stack: proponha uma change piloto pequena para
  provar o fluxo inteiro, medindo tasks bloqueadas pelo processo, falsos
  positivos dos gates e defeitos achados depois do GREEN.

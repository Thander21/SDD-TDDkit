---
name: learn
description: "Consolida aprendizados da sessão em regra do projeto, backlog, memória pessoal ou upstream do kit SDD, sem duplicar regra. Use quando o usuário pedir /learn ou para registrar lições da sessão; não use para revisão de código."
argument-hint: "[foco opcional]"
---

# /learn

Só do Claude Code (o Antigravity tem `/learn` nativo). Argumento opcional:
foco (`$ARGUMENTS`). Sem foco, cubra a sessão inteira.

## 0. Ancore sem adivinhar

Use a referência mais concreta: commit mostrado nesta conversa
(`git show <ref> --stat`). Não trate o `HEAD` como desta sessão sem prova.
Depois de compactação, releia os arquivos citados. Sem referência
confiável, diga que trabalhou só com a conversa.

## 1. Quatro destinos (proponha antes de editar, menos o 3)

| Tipo | Destino | Critério |
|---|---|---|
| Regra do projeto | `.agents/rules/<dominio>.md` (ou seção do projeto no `AGENTS.md`) | recorreria numa sessão parecida; refine regra próxima em vez de duplicar |
| Pendência | change ativa, item de backlog existente ou item novo `NN - Tema.md` | achado adiado, fora de escopo, ideia futura |
| Preferência pessoal | memória local do Claude Code (nunca o Git) | como o usuário prefere trabalhar |
| Upstream do kit | nota no `INBOX.md` do repositório do kit (caminho em `.sdd/kit.lock.json`, campo `fonte`) | lição de **método** (fluxo, gate, motor, skill do kit); nunca edite arquivo gerenciado no projeto |

- Regra nova: uma a três linhas, com `(origem: AAAA-MM-DD, ref curta)`; a
  história longa fica fora da regra.
- Três armadilhas no mesmo território: proponha uma regra de domínio com
  `paths`/`glob` ou um molde de persona.
- Contradição com regra existente: aponte e pergunte; não sobrescreva.

## 2. Depois de aplicar

Rode `sdd check` e reporte. Se quebrar, reveja a alteração.

## Saída

1. Referência usada (commit ou só conversa).
2. Diffs propostos (regra, pendência, upstream), aguardando OK.
3. Preferência gravada e onde.
4. Tipo sem achado: diga, em vez de forçar.

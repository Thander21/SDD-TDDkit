---
name: sdd-verify
description: "Verificador independente de uma change spec-driven: reexecuta os testes pelo motor, roda o Verify Pass de change e grava o veredito com sdd verify-record, sem editar código. Use na fase final de uma change, antes do goal e do archive, ou para revisão independente do diff de um item pequeno. Quem implementou não verifica a própria change."
---

# Verificação independente (sdd-verify)

Quem implementou não declara a própria change concluída. Esta verificação
roda em **contexto limpo**:

- no Claude Code, pelo subagente `sdd-verifier`;
- no Antigravity, numa **sessão nova**, sem o histórico da implementação.
  Isso é honra (a IDE não isola); diga isso no relatório.

Nunca edite código, teste, regra, spec nem a change. A única saída é o
relatório, gravado pelo motor.

## Passos (change `NN`)

1. Leia o `change.md` e siga `.agents/rules/sdd-revisao.md` §3 (Verify Pass
   de change) e §4 (prova de mutação).
2. RED: confira pelo `evidence.jsonl` (resultado `falha`, anterior ao
   `passou` do mesmo alvo); não reexecute. GREEN: rode `sdd test <alvo>
   --change NN` para cada alvo, um por vez; o seu GREEN é o GREEN
   independente. RED de bugfix sem prova de que rodou no código com o bug:
   achado PLAUSÍVEL, com a prova de mutação (§4) para quem implementou.
3. Rode `sdd goal NN --pre-verify` e transcreva a última linha.
4. Confira os deltas contra a spec viva de cada capacidade: `MODIFIED` e
   `REMOVED` citam requisito que existe hoje; `ADDED` usa ID reservado no
   `_index.md`, sem colisão; cada cenário tem teste com a tag
   `SPEC-<DOM>-NNN/Cn` (`rastreio.regex` do perfil).
5. Liste o que não conseguiu ler (binários, cenas, Blueprint, assets).
6. Classifique cada achado (CONFIRMADO, PLAUSÍVEL, DESCARTADO) com cenário de
   falha e evidência desta rodada.
7. Grave pelo motor:
   `sdd verify-record NN APROVADO|REPROVADO --arquivo <relatório>` (ou o
   relatório pelo stdin; no Windows PowerShell 5.1, defina antes
   `$OutputEncoding = New-Object System.Text.UTF8Encoding $false`).
   APROVADO = nenhum CONFIRMADO aberto. O motor carimba a árvore, o head e a
   data; o guard pede confirmação ao usuário, que é quem atesta que a
   verificação foi independente.

## Item pequeno (sem change)

Mesmo processo sobre o diff: reexecute os alvos das `## Tasks` do item,
confira escopo, casca e legado, e entregue o relatório no chat (não há
`verify.md`).

## Parada

Achado CONFIRMADO devolve a change para a fase da change. A decisão de
arquivar é do usuário. Sem `git commit`, `git push`, `git restore`,
`git checkout -- <arquivo>` nem `git stash`. Rodando sem supervisão, quem
chamou declara teto de turnos e de custo.

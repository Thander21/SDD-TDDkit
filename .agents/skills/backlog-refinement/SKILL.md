---
name: backlog-refinement
description: "Refina um item do backlog de specs em requisitos conferidos no código, recorta em unidades com nível e, com o item Pronto, abre a change em Draft ou as Tasks do item pequeno. Use quando pedirem para refinar ou levantar requisitos de um item do backlog, ou para abrir a change de um item. Não use para implementar."
---

# Refinamento do backlog

Etapa 0 do fluxo (`.agents/rules/sdd-fluxo.md` §2). Entrada: o item do
backlog (`<specs>/backlog/NN - Tema.md`) e o modo, `refinar` (padrão) ou
`abrir`. Sem item informado, liste os itens com a Prontidão de cada um e
pergunte qual.

## Modo refinar (Levantamento → Requisitos)

1. Leia o item inteiro, o `sdd-fluxo.md` e o `_index.md` das capacidades.
   Capacidade com spec viva: leia o `spec.md`; requisito vigente que o
   levantamento contradiz vira `MODIFIED` no recorte, nunca é ignorado.
2. Preserve o texto original em `## Levantamento`, sem reescrever.
3. Procure no código cada caminho, tabela, tela ou regra citada. Resultado
   na tabela "Estado atual no código" com `arquivo:linha`, ou "não existe".
4. "Solução" escrita no levantamento é hipótese: vira requisito funcional
   observável ou pergunta, nunca decisão. Regra de negócio cita a fonte
   (usuário, norma, código atual); sem fonte, é pergunta.
5. Recorte: uma unidade = uma capacidade ou um contrato, com nível
   (promoção automática aplicada), capacidade, tags de risco e dependências.
6. Pergunte só o que muda requisito, recorte ou nível; uma pergunta por vez,
   com a sua recomendação. Padrão óbvio vira requisito citando o padrão.
   Respostas entram na tabela com data.
7. Prontidão = `Requisitos`. Entregue: o que o código já tem, as unidades e
   as perguntas pendentes.

**Parada:** só o usuário marca `Pronto`, `Adiado` ou `Descartado`.

## Modo abrir (Pronto → change ou Tasks)

Pré-condição: `Prontidão: Pronto` e nenhuma pergunta sem resposta.

| Nível | Saída |
|---|---|
| Trivial | nota em `## Encaminhamento`; segue direto para implementação quando o usuário pedir |
| Pequeno | `## Tasks` no próprio item (RED → GREEN → REFACTOR, com `sdd test`) |
| Feature | `<specs>/changes/NN-slug/change.md` pelo molde, `status: Draft` |

- `NN` segue o número do item; várias features do mesmo item usam os
  próximos números livres em `backlog/`, `changes/` e `concluidas/`.
- Cada RF/RN vira cenário `SPEC-<DOM>-NNN/Cn`. Pergunta nova vai para
  `## Perguntas em aberto` da change. Registre a change em `## Encaminhamento`.
- Mova o item do backlog para `changes/NN-slug/origem/` (`git mv` se
  versionado): a change guarda a documentação que a gerou. Item com várias
  features fica na pasta da primeira; as seguintes citam esse caminho.

**Parada:** a IA nunca muda a change para `Approved`. Diga ao usuário que,
com as perguntas respondidas, ele aprova com `sdd approve NN P1`.

## Verificação antes de encerrar

- Toda linha de "Estado atual no código" tem evidência ou está marcada como
  hipótese; nenhuma solução virou decisão sem resposta do usuário.
- Toda unidade tem nível, capacidade e risco.
- No modo abrir: `sdd spec-lint` sem achado novo na change criada.

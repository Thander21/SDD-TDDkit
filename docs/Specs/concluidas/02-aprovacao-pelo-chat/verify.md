Veredito: APROVADO
arvore: 72e7cfd056cf5d06aa5cdcc8dd9a1d8cb7323366
head: e24ea4eb219191231d3667de2be677ffb8dfdb61
data: 2026-10-16T11:18:17.790Z
registrado-por: sdd verify-record
---
# Verificação independente da CHG-002 (4ª rodada)

## Escopo e modo

- Change `docs/Specs/changes/02-aprovacao-pelo-chat/`, verificada pelo subagente `sdd-verifier` (Claude Code), em contexto limpo e sem ter implementado. Nenhum arquivo do repositório foi editado; testes adversariais rodaram num script no scratchpad, que extrai `Test-SddFraseAprovacao` do kernel.
- Conferido nesta rodada: o `change.md`, o diff do motor (`SpecSimpleKit/kernel/tools/sdd/sdd.ps1:960-1074`), a cópia da raiz (`diff`: idêntica a `tools/sdd/sdd.ps1`), `SpecSimpleKit/tests/test_motor_aprovacao.ps1`, `SpecSimpleKit/tests/test_guard.ps1:86-88`, `run_all.ps1`, o ledger e `docs/Specs/capabilities/_index.md`.

## Evidência de checagem

- GREEN independente: `sdd test SpecSimpleKit/tests/test_motor_aprovacao.ps1 --change 02` → 28/28, PASSOU (5.1). `sdd test SpecSimpleKit/tests/test_guard.ps1 --change 02` → 100/100, PASSOU (5.1). A cobertura em 7 vem do `validate` full, PASS na árvore atual (`sdd status`).
- RED pelo ledger: o último RED do alvo (`falha`, exit 1, às 19:30:38 e às 19:31:34, árvore 48fc943f) vem antes do `passou` às 19:32:18 (árvore f4dbe909). A confiança é `exit`, como a Análise já declara para o perfil `powershell`.
- `sdd goal 02 --pre-verify` → última linha: `GOAL PASS (pre-verify)`.
- `sdd check` → `SDD CHECK PASS`.
- Deltas: o `_index.md` reserva SPEC-MOTOR-001 para a CHG-002 (`docs/Specs/capabilities/_index.md:22,33`), sem colisão. C1..C4 têm assert com a tag `[SPEC-MOTOR-001/Cn]`. R-1 está em `test_motor_aprovacao.ps1:26`; R-2 e R-3 estão em `test_guard.ps1:87-88`. Não há MODIFIED nem REMOVED.
- Escopo: os arquivos do `git diff --stat` estão todos no `impact`, com estas exceções. `docs/Specs/changes/05-guard-no-projeto/change.md` ganhou uma linha, a D8 da CHG-005, que é a parte dividida pela D7 desta change. O backlog 06 é novo e não faz parte da change, como foi informado.

### Achados anteriores

- A3, fechado: `Test-SddFraseAprovacao` compara as citações como texto (`[0-9]+`, `TrimStart('0')`, `sdd.ps1:970-973`). "aprovo P1 da change 99999999999" e "change 01 change 99999999999999999999999" devolvem `False`, sem exceção. O teste cobre o caso (`test_motor_aprovacao.ps1:60`). Um dígito não ASCII depois de "change" (U+0661, U+FF10/FF11) devolve `False`, sem exceção.
- A4, fechado: "aprovo P1 da change 01 e change 03" está no laço do C3 e recusa. A mutação `-contains` não foi refeita por mim, porque o verificador não edita código. Aceito a prova registrada na task porque o teste discrimina a mutação: com `-contains`, a frase seria aceita e o assert de exit 1 falharia.
- A1/A1-R (D10), A2 (D7), B1 (D8), B2, B3 (D7) e B4 (D9) continuam fechados. Data e "os 2 portoes" seguem recusados pelo teste; a documentação está no diff; frase negativa ("desaprovo P1 da change 01") passa, como a D8 aceita.
- A frase real "aprovo P1 e P2 da change 02" vale para P1 e P2 da 02 (`True`/`True`). As linhas de `## Aprovações` estão intactas, e o `goal` passou do portão.

### Frases adversariais (resultado da função nesta rodada, alvo 01)

Aceitas: "change 1", "change 001", "CHG_01", "change #01", "Change 01" com "p1" minúsculo, "change\t01", "change-01", "change 01, 03", "change 01/03", "change 01-03" e "change 03x e change 01".
Recusadas: "change 010", "change 10", "P12", "das changes 01 e 03", "change 01 e chg 3" e "change ١".

## Achados

### PLAUSÍVEL (não bloqueia)

- **P-1: citação de outra change com dígito não ASCII ou sufixo de letra é ignorada.**
  - Cenário: `Test-SddFraseAprovacao 'aprovo P1 da change 01 e change ٣' P1 01` → `True`, e o mesmo vale para "change 03x e change 01". O regex `[0-9]+\b` (`sdd.ps1:971`) não lê essas formas como citação, então a regra da D10 de recusar frase que cita outra change não se aplica a elas.
  - Por que não é CONFIRMADO: a frase é do usuário (D5, honra) e cita a change 01 com todas as letras. Pelo modelo de ameaça do núcleo (agente cooperativo, não fraude), é improvável aparecer por descuido.
  - Proposta, adiável: tratar `\d` Unicode ou `[0-9]+\w` depois de change/CHG como citação inválida que recusa.
- **P-2: o `[int]` sobre o argumento NN (`sdd.ps1:964`) ainda lança exceção com NN gigante** (`approve 99999999999 P1 --frase ...` → ERRO, exit 2). Isso vem do argumento da CLI, não da frase. Sem `--frase`, um NN inexistente também sai com ERRO pelo `Find-SddChange`, então é erro de uso coerente e fica fora do contrato do C3. Proposta, adiável: usar a mesma comparação por texto para o NN.

## Descartados na verificação

- "change 01, 03" ou "change 01/03" aprovarem a 01: pela letra da D10, o número solto depois da vírgula não cita change, e a frase aprova de fato a change citada.
- "desaprovo P1 da change 01" aprovar: aceito pela D8.
- NN "0" ou "00" com "change 0": o alvo vira texto vazio e casa, mas `Find-SddChange` recusa a change inexistente. Sem efeito.
- Forjar a linha de aprovação pela frase: aspas viram `'`, quebras de linha são colapsadas, e a linha já carrega "(sdd approve" antes da frase. Não abre caminho novo.

## Não verificável nesta rodada

- `SpecSimpleKit/Metodologia SDD.ai`: binário, não lido.
- O GREEN em pwsh 7 do alvo pelo `sdd test` não foi refeito; vale o `validate` full PASS da árvore atual.
- A prova de mutação do A4 não foi reexecutada pelo verificador.

## Resumo da recomendação

- **Corrigir agora:** nada; nenhum CONFIRMADO aberto.
- **Adiar:** P-1 e P-2, num item de backlog do motor, se o usuário quiser.
- **Próximo passo:** `sdd goal 02` completo e, a pedido do usuário, o archive (Pós-GOAL).
- **Não fazer:** reabrir a D10 por causa do P-1 sem decisão do usuário.

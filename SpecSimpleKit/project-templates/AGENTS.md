# AGENTS.md

<!-- sdd-kit:begin -->
<!-- sdd-kit:end -->

## Projeto

> Seção do projeto, preenchida pela skill `sdd-bootstrap`. Fato cita a fonte
> (`arquivo:linha`, decisão ou doc com data); o que não foi conferido fica
> marcado como hipótese. O bloco acima é do kit e é reescrito no update.

### O que é

<Uma linha: o que o projeto faz e para quem.>

### Stack, pastas e camadas

<Stack e versões, pastas principais, o que pode importar o quê.>

### Comandos

| Momento | Comando |
|---|---|
| Depois de alterar | `powershell -File tools/sdd/sdd.ps1 check` |
| Antes de commit e no fecho da change | `powershell -File tools/sdd/sdd.ps1 validate` |
| RED e GREEN de uma task | `powershell -File tools/sdd/sdd.ps1 test <alvo>` |
| Parada da change | `powershell -File tools/sdd/sdd.ps1 goal <NN>` |
| Portão (frase do usuário no chat) | `powershell -File tools/sdd/sdd.ps1 approve <NN> P1\|P2 --frase "aprovo P1 da change NN"` |

### Convenções

<Nomes, idioma, formatação, testes: o que o código já mostra.>

### Riscos do projeto

| Tag | Promove a feature? | Invariantes | Cenário obrigatório | Exige fonte normativa? |
|---|---|---|---|---|

### Regras de domínio

<Índice: uma linha por arquivo em `.agents/rules/` do projeto, criado pelo
`learn` quando houver 3 armadilhas do mesmo território.>

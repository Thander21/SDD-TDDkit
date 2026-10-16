# INBOX do SpecSimpleKit

Lições de **método** vindas dos projetos (skill `learn`, destino "upstream do
kit"). Nada aqui é regra: na próxima release, cada nota vira mudança no
`kernel/` com teste, vira item adiado com gatilho, ou é descartada com motivo.

| Data | Projeto | Lição (sintoma → causa → proposta) | Evidência | Destino |
|---|---|---|---|---|
| 2026-10-16 | SDD-TDDkit (CHG-002) | Regra nova de interpretação de texto (frase de aprovação) reprovou 3 vezes no verificador, sempre por caso de borda que o teste não tinha → o RED cobria só o caminho feliz e uma frase inválida óbvia → no molde/fluxo, cenário de parsing nasce com uma lista de entradas adversariais (outro número, número solto, número gigante, dois alvos) já no primeiro RED | `docs/Specs/concluidas/02-aprovacao-pelo-chat/verify.md`; achados A1, A1-R, A3, A4 | próxima release |

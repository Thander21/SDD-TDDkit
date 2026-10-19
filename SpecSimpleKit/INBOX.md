# INBOX do SpecSimpleKit

Lições de **método** vindas dos projetos (skill `learn`, destino "upstream do
kit"). Nada aqui é regra: na próxima release, cada nota vira mudança no
`kernel/` com teste, vira item adiado com gatilho, ou é descartada com motivo.

| Data | Projeto | Lição (sintoma → causa → proposta) | Evidência | Destino |
|---|---|---|---|---|
| 2026-10-16 | SDD-TDDkit (CHG-002) | Regra nova de interpretação de texto (frase de aprovação) reprovou 3 vezes no verificador, sempre por caso de borda que o teste não tinha → o RED cobria só o caminho feliz e uma frase inválida óbvia → no molde/fluxo, cenário de parsing nasce com uma lista de entradas adversariais (outro número, número solto, número gigante, dois alvos) já no primeiro RED | `docs/Specs/concluidas/02-aprovacao-pelo-chat/verify.md`; achados A1, A1-R, A3, A4 | próxima release |
| 2026-10-19 | SDD-TDDkit (CHG-001/006) | Produto continha resíduos legados (instalar.cmd, tests/), tarefas misturadas no change.md e ausência de mapa de skills → produtos autocontidos exigem zero resíduo do kit (testes moram na oficina), tarefas geradas em tasks.md separado pós-P1 para aprovação conjunta em P2 com loop contínuo pós-P2, e matriz explícita de skills em cada fase do ciclo | CHG-001/006; test_install_modo_pasta.ps1; README.md | implementado |

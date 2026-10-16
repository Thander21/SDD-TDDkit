# Capacidades e IDs

> Registro único de capacidades e de IDs `SPEC-<DOM>-NNN`. Reserve o ID aqui
> no P1, antes de usá-lo. O contador só sobe; ID removido nunca volta.
> "Origem no código" é a fonte única (a spec viva repete a mesma).

## Capacidades

| Capacidade | Domínio | Origem no código | Spec viva |
|---|---|---|---|
| instalador | `INST` | `SpecSimpleKit/install.ps1`, `SpecSimpleKit/instalar.cmd`, `SpecSimpleKit/project-templates/` | — |
| motor | `MOTOR` | `SpecSimpleKit/kernel/tools/sdd/sdd.ps1` | `capabilities/motor/spec.md` |
| guard | `GUARD` | `SpecSimpleKit/machine/` | — |
| perfis | `PERFIL` | `SpecSimpleKit/profiles/` | — |
| fluxo | `FLUXO` | `SpecSimpleKit/kernel/.agents/`, `SpecSimpleKit/kernel/.claude/`, `SpecSimpleKit/kernel/AGENTS.kit.md`, `SpecSimpleKit/kernel/Docs/Specs/_templates/` | — |

## Contadores por domínio

| Domínio | Último ID |
|---|---|
| `INST` | 005 |
| `MOTOR` | 001 |
| `GUARD` | 004 |

## IDs reservados

| ID | Change | Capacidade |
|---|---|---|
| SPEC-INST-001 | CHG-001 | instalador |
| SPEC-INST-002 | CHG-001 | instalador |
| SPEC-INST-003 | CHG-001 | instalador |
| SPEC-INST-004 | CHG-001 | instalador |
| SPEC-MOTOR-001 | CHG-002 | motor |
| SPEC-GUARD-001 | — (reservado e liberado antes do P1 da CHG-002; não volta) | guard |
| SPEC-GUARD-002 | CHG-005 | guard |
| SPEC-GUARD-003 | CHG-005 | guard |
| SPEC-GUARD-004 | CHG-005 | guard |
| SPEC-INST-005 | CHG-005 | instalador |

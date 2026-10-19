# Capacidades e IDs

> Registro único de capacidades e de IDs `SPEC-<DOM>-NNN`. Reserve o ID aqui
> no P1, antes de usá-lo. O contador só sobe; ID removido nunca volta.
> "Origem no código" é a fonte única (a spec viva repete a mesma).

## Capacidades

| Capacidade | Domínio | Origem no código | Spec viva |
|---|---|---|---|
| instalador | `INST` | `SpecSimpleKit/install.ps1`, `SpecSimpleKit/instalar.cmd`, `SpecSimpleKit/project-templates/` | `capabilities/instalador/spec.md` |
| motor | `MOTOR` | `SpecSimpleKit/kernel/tools/sdd/sdd.ps1` | `capabilities/motor/spec.md` |
| guard | `GUARD` | `SpecSimpleKit/kernel/tools/sdd/guard.ps1`, `SpecSimpleKit/kernel/tools/sdd/edit_guard.ps1` | `capabilities/guard/spec.md` |
| perfis | `PERFIL` | `SpecSimpleKit/profiles/` | — |
| fluxo | `FLUXO` | `SpecSimpleKit/kernel/.agents/`, `SpecSimpleKit/kernel/.claude/`, `SpecSimpleKit/kernel/AGENTS.kit.md`, `SpecSimpleKit/kernel/Docs/Specs/_templates/` | — |

## Contadores por domínio

| Domínio | Último ID |
|---|---|
| `INST` | 005 |
| `MOTOR` | 002 |
| `GUARD` | 004 |
| `FLUXO` | 003 |

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
| SPEC-FLUXO-001 | CHG-006 | fluxo |
| SPEC-FLUXO-002 | CHG-003 | fluxo |
| SPEC-MOTOR-002 | CHG-007 | motor |
| SPEC-FLUXO-003 | CHG-004 | fluxo |

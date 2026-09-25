---
id: 260924-tbo
slug: corrigir-discrepancia-sem-orcamento-dash
status: complete
date: 2026-09-24
---

# SUMMARY

## Result

Dashboard spent for projects now matches Financeiro JTD (`hours × current salary`).

## Root cause

| Query | Formula | Finalização do sistema |
|-------|---------|------------------------|
| Dashboard `list_projects_budget_summary` | `SUM(pc.amount)` | 8567.59 → -71% |
| Financeiro `get_k_cost_summary` | `SUM(hours × ou.salary)` | 248.86 → healthy |

Old charges froze `hourly_rate=3000`; current salary is `40`. Amount stayed wrong.

## Changes

1. **zoc-be-api** `f3f187b` — migration `20260925001125_list_projects_budget_summary_jtd_salary.sql`
   - `list_projects_budget_summary.total_spent` = `SUM(hours_worked * salary)`
   - same for `generate_project_budget_notifications`
   - Applied on remote project `qmafoycwactjmyribxup`
2. **zoc-fe** `b94e0db` — label: exhausted → "Orçamento esgotado" (not "Sem orçamento")

## Verify

```sql
select total_spent from list_projects_budget_summary(<org>)
where id = 'b6d8b26d-740d-453b-96c7-c96b07ccf325';
-- => 248.86
```

Refresh dashboard → Sistema ZOC / Finalização ~+95% remaining, no false exhausted alert.

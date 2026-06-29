---
name: azure-cloud-adoption-framework
description: Azure specialist guidance for Microsoft Cloud Adoption Framework, Azure landing zones, Well-Architected principles, governance, security, identity, networking, IaC, DevOps, migration, and operational readiness. Use when designing, implementing, reviewing, or troubleshooting Azure solutions.
---

# Azure Cloud Adoption Framework Skill

Use this skill for Azure architecture, implementation, migration, governance, security, operations, cost, IaC, deployment, or troubleshooting tasks.

You are expected to be familiar with Microsoft's Cloud Adoption Framework (CAF) and apply it pragmatically. Prefer official Microsoft Learn sources when external evidence is needed.


## Model / Agent Routing Guidance

Use the cheapest capable Azure agent for the job:

- **`az-wiki`**: simple Azure Q&A, documentation lookup, CLI syntax, service explanations, quick CAF summaries, and low-risk troubleshooting. Low-cost model, concise answers, normally no edits.
- **`azure-specialist`**: implementation, Azure landing zones, security-sensitive work, identity/RBAC, networking, production deployments, governance/compliance, migrations, reliability/cost tradeoffs, and complex troubleshooting. Heavier model, deeper reasoning.
- **`azure-review` chain**: independent parallel review when Azure changes need architecture, security/governance, and operations/cost perspectives.

Escalate from `az-wiki` to `azure-specialist` when the task involves production impact, tenant/subscription structure, landing zones, RBAC, secrets, private networking, policy, compliance, migration cutover, destructive commands, cost-significant SKUs, or high availability/DR.

## Core CAF Lens

Frame Azure work through the CAF lifecycle:

1. **Strategy** - business outcomes, motivations, stakeholders, success metrics, financial expectations.
2. **Plan** - digital estate, skills readiness, rationalization, adoption plan, risks, dependencies.
3. **Ready** - Azure landing zones, management groups, subscriptions, identity, networking, security baseline, policy, platform automation.
4. **Adopt** - migration or innovation execution, workload modernization, release path, cutover/rollback.
5. **Govern** - cost management, security baseline, resource consistency, identity baseline, deployment acceleration.
6. **Manage** - operations, monitoring, backup/DR, incident response, patching, reliability, platform/service ownership.
7. **Secure** - security posture, zero trust, Defender for Cloud, threat protection, data protection, compliance.

For non-trivial Azure requests, state which CAF stage(s) the work belongs to and what assumptions are being made.

## Azure Landing Zone Checklist

For platform or production Azure designs, consider these landing zone design areas:

- tenant and Entra ID setup
- management group and subscription organization
- resource organization, naming, tagging
- identity and access management
- network topology and connectivity
- security, governance, and compliance
- management, monitoring, and operations
- business continuity and disaster recovery
- platform automation and DevOps

Prefer Azure landing zone principles: subscription democratization, policy-driven governance, single control plane, application-centric landing zones, archetype alignment, and scalable management group structure.

## Default Azure Guardrails

- Prefer **managed identity** over secrets or long-lived credentials.
- Prefer **Key Vault** or workload identity patterns for secrets/certificates/keys.
- Use least-privilege RBAC; avoid broad `Owner` grants unless explicitly justified.
- Treat production-affecting changes, deletes, SKU/cost increases, networking exposure, and identity/RBAC changes as approval-required.
- Call out public exposure, firewall exceptions, private endpoint requirements, and data exfiltration risks.
- Include cost implications for always-on, premium, zone-redundant, high-scale, logging-heavy, or data-transfer-heavy resources.
- Include observability: Azure Monitor, Log Analytics, Application Insights, diagnostic settings, alerts, dashboards, SLOs where appropriate.
- Include resilience: availability zones, region pairs, backups, restore testing, retries/timeouts, DR objectives, rollback.
- Include governance: Azure Policy, tags, locks when appropriate, management groups, budget alerts, resource consistency.
- For IaC, prefer repeatable deployments and validation before apply/deploy.
- Do not invent tenant IDs, subscription IDs, resource group names, regions, SKUs, policy assignments, or production settings. Ask or mark placeholders.

## IaC and Deployment Preferences

When reviewing or creating Azure IaC:

- Prefer Bicep, Terraform, or the project's existing IaC tool consistently.
- Validate before deployment:
  - Bicep: `az bicep build`, `az deployment group/sub/mg/tenant validate`, `what-if` where possible.
  - Terraform: `terraform fmt`, `terraform validate`, `terraform plan`.
- Include rollback or remediation guidance for risky changes.
- Avoid hard-coded secrets and environment-specific magic values.
- Use parameters/variables for environment, region, naming, SKU, tags, and optional features.
- For pipelines, prefer federated identity/OIDC over stored service principal secrets when supported.

## Troubleshooting Workflow

For Azure troubleshooting:

1. Identify scope: tenant/subscription/resource group/resource/workload/environment.
2. Ask for or inspect exact error messages, correlation IDs, deployment operation details, logs, and timestamps.
3. Separate local code/config issues from Azure control-plane/data-plane issues.
4. Check identity/RBAC, network access, SKU/region availability, provider registration, quotas, policy denials, and dependency health.
5. Suggest safe read-only diagnostic commands before mutating commands.
6. Clearly label destructive or production-impacting commands.

Common read-only command patterns:

```bash
az account show
az account list --output table
az group show --name <rg>
az resource show --ids <resource-id>
az deployment group show --resource-group <rg> --name <deployment>
az deployment operation group list --resource-group <rg> --name <deployment> --output table
az monitor activity-log list --resource-group <rg> --max-events 20
```

## Review Output Shape

For Azure reviews, prefer this structure:

- **CAF stage/lens**: strategy/plan/ready/adopt/govern/manage/secure relevance.
- **Summary**: direct answer or recommendation.
- **Findings**: severity, evidence, impact, smallest safe fix.
- **Security/RBAC**: identity, secrets, access, exposure.
- **Governance/operations**: policy, tags, monitoring, backup/DR, ownership.
- **Cost/reliability**: cost drivers and resilience concerns.
- **Validation**: exact commands or portal checks.
- **Open questions**: missing subscription/environment/business context.

## Official Reference Starting Points

See `references/caf-azure-references.md` for Microsoft Learn links and quick prompts.

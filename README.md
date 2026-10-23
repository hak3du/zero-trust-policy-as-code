# Zero Trust Infrastructure Guardrails — Terraform + OPA

Standalone portfolio demonstrator: evaluate Terraform plan JSON with Open Policy Agent (OPA) and report selected cloud misconfigurations before deployment.

**Scope disclaimer:** This is not a production deployment or proof of complete NIST SP 800-207 conformance. Rules cover selected AWS resource patterns and need validation against real provider versions and organization requirements.

## Controls

- Public IPv4/IPv6 ingress for SSH (TCP/22) and RDP (TCP/3389).
- Explicitly unresolved security-group ingress in a Terraform plan is denied rather than assumed safe.
- EBS volumes explicitly configured without encryption.
- S3 public-access-block settings explicitly disabled.

## Validation

Run the local policy regression suite and fixture checks from the repository root:

```powershell
.\validate.ps1
```

The reproducible Terraform AWS-provider integration suite is documented in [terraform-integration/README.md](./terraform-integration/README.md).

Run on Windows PowerShell:

```powershell
.\scripts\test-terraform-aws.ps1 -TerraformPath "$HOME\Tools\Terraform\terraform.exe" -OpaPath "$HOME\Tools\OPA\opa.exe"
```

For a focused recruiter-facing walkthrough, see the [60-second demo recording script](./docs/DEMO_SCRIPT.md). This is a script for recording a real terminal run, not a claim that a video has already been published.

### Observed integration results

The fresh-plan runner was executed locally on 2026-10-23 using Terraform 1.17.0, AWS provider 6.70.0, and OPA 1.21.4 on Windows. The runner reported **ALL TERRAFORM/AWS INTEGRATION CHECKS PASSED**:

| Scenario | Expected denials | Actual denials | Result |
|---|---:|---:|---|
| Public SSH (TCP/22 to 0.0.0.0/0) | 1 | 1 | PASS |
| Public RDP (TCP/3389 to 0.0.0.0/0) | 1 | 1 | PASS |
| Security group with no ingress block | 0 | 0 | PASS |

These are local, plan-only integration tests. The fixtures use a placeholder VPC ID and dummy credentials. The runner calls Terraform init, plan, and show, then evaluates the generated JSON with OPA; it never invokes `terraform apply`. No AWS infrastructure was deployed or changed.

The generated `.tfplan` and JSON files remain local under `artifacts/terraform-aws/` and are intentionally not committed by default. Terraform plan artifacts can expose infrastructure details or sensitive values in other configurations; review and sanitize before sharing.

**Scope limitation:** these three cases validate only the tested SSH, RDP, and no-ingress scenarios. Recursive child-module configuration and all nested/partial unknown-value cases still require validation. This is not a production deployment or proof of complete NIST SP 800-207 conformance.

## Tooling and CI

The local baseline used Terraform 1.17.0 and OPA 1.21.4 on Windows/amd64. Hosted GitHub Actions previously failed before job startup because of an account billing lock; re-check CI status rather than interpreting that as a policy test failure.

## Accurate resume wording

> Built and locally validated a Terraform plan policy gate with OPA/Rego, including automated AWS-provider integration tests that detected tested public SSH/RDP exposures and accepted a no-ingress scenario.

Do not claim measured impact, production deployment, comprehensive security coverage, or complete NIST SP 800-207 conformance without additional evidence. See `PRO_NOTES.md`.

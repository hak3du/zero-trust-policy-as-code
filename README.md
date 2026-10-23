# Zero Trust Infrastructure Guardrails — Terraform + OPA

Standalone portfolio demonstrator: evaluate Terraform plan JSON with Open Policy Agent (OPA) and report selected cloud misconfigurations before deployment.

**Scope disclaimer:** This is not a production deployment or proof of complete NIST SP 800-207 conformance. Rules cover selected AWS resource patterns and need validation against real provider versions and organization requirements.

## Controls

- Public IPv4/IPv6 ingress for SSH (TCP/22) and RDP (TCP/3389).
- Explicitly unresolved security-group ingress in a Terraform plan is denied rather than assumed safe.
- EBS volumes explicitly configured without encryption.
- S3 public-access-block settings explicitly disabled.

## Validation

The local validation script runs the Rego tests and evaluates the compliant and noncompliant JSON fixtures:

```powershell
.\validate.ps1
```

Or use OPA directly:

```bash
opa test policy -v
bash scripts/check.sh
```

### Terraform AWS provider integration suite

A reproducible, isolated integration suite is available under [terraform-integration](./terraform-integration/README.md). It pins hashicorp/aws v6.70.0 and generates fresh Terraform plans for public SSH, public RDP, and a security group with no ingress block. OPA evaluates the JSON produced by `terraform show -json`.

Run on Windows PowerShell from the repository root:

```powershell
.\scripts\test-terraform-aws.ps1 -TerraformPath "$HOME\Tools\Terraform\terraform.exe" -OpaPath "$HOME\Tools\OPA\opa.exe"
```

The runner is designed to use dummy credentials and a placeholder VPC ID. It executes init, plan, show, and OPA evaluation only—never `terraform apply`. It writes local plan and JSON artifacts to `artifacts/terraform-aws/`. Those generated JSON files are not considered verified repository artifacts until the suite has actually been run and the outputs reviewed.

Previously observed local integration results against Terraform-generated plans from AWS provider v6.70.0 were: public SSH = 1 denial, public RDP = 1 denial, compliant no-ingress = 0 denials. The reproducible runner itself still needs to be executed in a fresh clone before claiming its end-to-end run passed.

**Scope limitation:** recursive child-module configuration and all nested/partial unknown-value cases still require validation. This is not a production deployment or proof of complete NIST SP 800-207 conformance. No cloud infrastructure has been applied or changed.

## Tooling and CI

The local baseline used Terraform 1.17.0 and OPA 1.21.4 on Windows/amd64. Hosted GitHub Actions previously failed before job startup because of an account billing lock; re-check CI status rather than interpreting that as a policy test failure.

## Accurate resume wording

> Built a Terraform plan policy gate with OPA/Rego to detect selected cloud misconfigurations before deployment, supported by policy tests, JSON fixtures, and a Terraform AWS-provider integration suite.

Only claim measured impact or end-to-end test success after collecting evidence. See [PRO_NOTES.md](./PRO_NOTES.md).

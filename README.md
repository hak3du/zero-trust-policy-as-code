# Zero Trust Infrastructure Guardrails — Terraform + OPA

Standalone portfolio demonstrator: evaluate Terraform plan JSON with Open Policy Agent (OPA) and report selected cloud misconfigurations before deployment.

**Scope disclaimer:** This is not a production deployment or proof of complete NIST SP 800-207 conformance. Rules cover selected AWS resource patterns and need validation against real provider versions and organization requirements.

## Controls
- Public IPv4/IPv6 ingress for SSH (TCP/22) and RDP (TCP/3389).
- EBS volumes explicitly configured without encryption.
- S3 public-access-block settings explicitly disabled.

## Run
Requires OPA CLI 1.x and Make (or Bash/WSL/Git Bash on Windows).

```bash
opa version
opa test policy -v
bash scripts/check.sh
```

The compliant fixture should yield zero violations; the noncompliant fixture should yield one or more.

To evaluate a real plan in a test environment:

```bash
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
opa eval --format pretty --data policy --input tfplan.json 'data.terraform.guardrails.violations'
```

Review and sanitize plan JSON before sharing; it can contain sensitive infrastructure details.

## Accurate resume wording
> Built a Terraform plan policy gate with OPA/Rego to detect selected cloud misconfigurations before deployment, supported by positive/negative fixtures and automated policy tests.

Only claim measured impact or test success after collecting evidence. See `PRO_NOTES.md`.

# Terraform + AWS provider integration tests

These isolated fixtures validate OPA against fresh Terraform-generated plan JSON using the pinned AWS provider hashicorp/aws 6.70.0.

## Safety boundary

- Runs terraform init, terraform plan, terraform show -json, and opa eval only.
- Never runs terraform apply or destroys infrastructure.
- Fixtures use a placeholder VPC ID and dummy credentials.
- The runner overrides AWS credential environment variables with dummy values and disables EC2 metadata lookup.
- Terraform init may need internet access to download the pinned provider.
- Generated JSON is written to artifacts/terraform-aws. Real plans can contain sensitive information; review before publishing.

## Requirements

- Terraform CLI (local baseline: 1.17.0)
- OPA CLI 1.x (local baseline: 1.21.4)
- PowerShell 5.1+ or PowerShell 7+

## Run from repository root

    .\scripts\test-terraform-aws.ps1 -TerraformPath "$HOME\Tools\Terraform\terraform.exe" -OpaPath "$HOME\Tools\OPA\opa.exe"

Expected denial counts:

| Case | Expected denials |
|---|---:|
| Public SSH (TCP/22 to 0.0.0.0/0) | 1 |
| Public RDP (TCP/3389 to 0.0.0.0/0) | 1 |
| Security group with no ingress block | 0 |

The script exits with an error if Terraform fails or a denial count differs. It writes actual Terraform show -json output and local .tfplan files to artifacts/terraform-aws. Generated plan artifacts are created when the suite runs; they are not hand-authored examples.

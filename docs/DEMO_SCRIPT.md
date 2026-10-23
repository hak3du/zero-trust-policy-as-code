# 60-Second Portfolio Demo — Zero Trust Policy-as-Code

## Goal
Show a hiring manager the working control, the test result, and the engineering judgment in one minute.

## Capture checklist
- Use a clean terminal with the project root visible.
- Do not show access tokens, personal paths, unrelated browser tabs, or private environment variables.
- Use the existing local project and tools; do not run `terraform apply`.
- Keep the terminal font large enough to read in a 1080p recording.
- If recording a fresh run, ensure Terraform and OPA are installed and the required files are present before starting the capture.

## 60-second narration and screen plan

**0–8 seconds — Problem**
Narration: “This project evaluates Terraform plans before infrastructure deployment, using Open Policy Agent and Rego to enforce selected cloud-security guardrails.”

Screen: Show the repository name and the policy file.

**8–20 seconds — Policy**
Narration: “The policy checks selected high-risk configurations, including public SSH/RDP exposure, explicitly disabled EBS encryption, and disabled S3 public-access protections. It also handles a specific unresolved-ingress plan case.”

Screen: Briefly show the relevant Rego rules. Do not imply exhaustive AWS coverage.

**20–38 seconds — Unit validation**
Narration: “The local validation script runs the policy tests and checks both compliant and noncompliant fixtures.”

Screen: Run from the repository root:
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\validate.ps1"
```

Show the actual final output. The documented result was 14/14 tests, zero denials for the compliant fixture, four denials for the noncompliant fixture, and `ALL VALIDATION CHECKS PASSED.` If a new run differs, report the actual result rather than using the historical result.

**38–53 seconds — Provider-backed integration**
Narration: “I also built a repeatable Terraform/AWS provider integration runner. It creates plans and evaluates them with OPA; it does not deploy infrastructure.”

Screen: Run the integration command with the correct local executable paths:
```powershell
.\scripts\test-terraform-aws.ps1 -TerraformPath "$HOME\Tools\Terraform\terraform.exe" -OpaPath "$HOME\Tools\OPA\opa.exe"
```

Show all three actual outcomes: public SSH denied, public RDP denied, and compliant no-ingress allowed. The previously observed local run passed 3/3 scenarios.

**53–60 seconds — Close**
Narration: “The result is a reproducible preventive policy check that can be extended with additional regression tests and CI enforcement. The current demo is plan-only and does not claim a live AWS deployment.”

Screen: Show the repository URL:
https://github.com/hak3du/zero-trust-policy-as-code

## Publication checklist
- [ ] Record the real terminal run; do not fabricate terminal footage.
- [ ] Review the recording for secrets and personal information.
- [ ] Upload it to a public or unlisted video host.
- [ ] Verify the video URL in a signed-out/private browser window.
- [ ] Add the verified URL to the repository README and LinkedIn Featured section.

# Professional Engineering Notes — Zero Trust Policy-as-Code

This is the authoritative factual build log. Distinguish implemented, tested, observed, and unverified. Record commands, tool versions, output, failures, fixes, commit SHAs, and evidence URLs.

## Project control
- Project: Terraform + OPA/Rego infrastructure guardrails
- Repository: https://github.com/hak3du/zero-trust-policy-as-code
- Status: Source files published to `main`; local validation completed with OPA 1.21.4 on Windows (12/12 unit tests passed; compliant fixture returned 0 denials; noncompliant fixture returned 4 denials). The local `validate.ps1` script completed all three validation stages successfully. Hosted GitHub Actions is blocked before job start by an account billing lock.
- No cloud infrastructure has been deployed or changed.
- Do not claim passing tests, measured impact, NIST conformance, or production deployment without evidence.

## Engineering log

### 2026-10-22 — Step 1: Scope
Decision: keep this project in its own repository, independent of `hak3du/portfolio`.

Acceptance criteria:
1. OPA evaluates Terraform plan JSON.
2. Selected risky SSH/RDP exposure, unencrypted EBS, and disabled S3 public-access settings produce violations.
3. Unit tests cover positive and negative cases.
4. Compliant fixture returns zero violations.
5. Noncompliant fixture returns one or more violations.
6. CI runs tests and fixture checks.
7. Every material step and result is logged here.

### 2026-10-22 — Step 2: Initial source package
Prepared policy, unit tests, two plan fixtures, local test script, Makefile, README, and CI workflow. Source was authored but execution was not verified.

### 2026-10-23 — Step 3: Repository created and files published
Confirmed `hak3du/zero-trust-policy-as-code` exists, is public, and uses `main` as its default branch. Connected GitHub permissions report push access. Published the README, Rego policy and tests, two fixtures, local check script, Makefile, workflow, and this notes file.

Initial publication commits (one per file):
- README.md — `b1632c9f492d5956f3c3c49298cb8a4dfe203b57`
- policy/guardrails.rego — `53aa28860e69c291bcd7854668c2c3279f707baf`
- policy/guardrails_test.rego — `cfcab1a4abfa0ec3ada1537a768ceafccfed3e10`
- examples/compliant-plan.json — `075bb8c09ea095344b69ed5d7fbd88f20cf7da0e`
- examples/noncompliant-plan.json — `68674d854ceb2f7ebd31bc08e327694abd64fef7`
- scripts/check.sh — `1c0ba1907d7fc33c913e9ff3c6ac33b2baeca1c8`
- Makefile — `6ef2b927efd5c4b07a6b3f9fd0268cbcef33af95`
- Initial workflow — `a6466f4bd03f51c441bf39d54eec12aaa3f97e76`
- Initial PRO_NOTES.md — `b7fc010365b132e8e7e87a5144ef0d48795a250e`

### 2026-10-23 — Step 4: Initial validation observations
- Parsed both example plan fixtures with Python's JSON parser: **PASS**.
- Initial GitHub Actions runs failed before exposing steps. The latest run's UI later showed the explicit message: `The job was not started because your account is locked due to a billing issue.` This is an account-level runner/billing block, not evidence of a Rego test failure. The Ubuntu 26 migration notice is informational.
- Workflow triggers were narrowed to policy, fixture, and workflow changes so notes-only commits do not trigger CI. Workflow change commit: `ca8b69b98bc0cafef41b4ba9cfcf5415218f352c`.
- Hosted GitHub Actions remains blocked by the billing lock. Local validation was therefore performed manually on Windows, using the downloaded OPA executable.

### 2026-10-23 — Step 5: Manual OPA validation on Windows
- OPA version command: `& "$HOME\Tools\OPA\opa.exe" version`.
- Observed version: **OPA 1.21.4**, Rego v1, Windows/amd64; build timestamp reported by the executable: `2026-10-23T13:00:56Z`.
- Command: `opa test policy -v` (invoked through `$HOME\Tools\OPA\opa.exe`). Result: **PASS 4/4**. Passing tests: public SSH denied; unencrypted EBS denied; private SSH allowed; destroy-only change ignored.
- Command: `opa eval --format raw --data policy --input examples/compliant-plan.json "count(data.terraform.guardrails.deny)"`. Observed output: `0` — **PASS**, compliant fixture produced no denials.
- Command: `opa eval --format raw --data policy --input examples/noncompliant-plan.json "count(data.terraform.guardrails.deny)"`. Observed output: `4` — **PASS**, noncompliant fixture produced four denials.
- Command: `opa eval --format pretty --data policy --input examples/noncompliant-plan.json "data.terraform.guardrails.violations"`. Observed four violations:
  1. `EBS volume encryption explicitly disabled: aws_ebs_volume.data`
  2. `RDP (TCP/3389) exposed to the public internet: aws_security_group.rdp`
  3. `S3 public-access protection 'block_public_policy' disabled: aws_s3_bucket_public_access_block.data`
  4. `SSH (TCP/22) exposed to the public internet: aws_security_group.admin`
- Interpretation: unit tests and both example-fixture checks passed locally. This is not proof of full Terraform-provider behavior, production readiness, complete control coverage, or NIST SP 800-207 conformance. No cloud infrastructure was deployed or changed.


### 2026-10-23 — Step 6: Expanded policy tests and repeatable local validation
- Added test coverage for public RDP over IPv4/IPv6, public SSH over IPv6, all four S3 public-access-block settings, and security-group ingress explicitly marked unknown in Terraform plan JSON.
- Reproduced the unknown-ingress gap: the new test failed while the previous 11 tests passed. Added a Rego denial for non-delete security-group changes where `change.after_unknown.ingress == true` and `change.after` is an object.
- Re-ran `opa test policy -v`: **PASS 12/12** on OPA 1.21.4, Windows/amd64.
- Re-ran the compliant fixture evaluation: **0 denials**.
- Re-ran the noncompliant fixture evaluation: **4 denials**. Observed messages identify unencrypted EBS, public RDP, disabled S3 `block_public_policy`, and public SSH.
- Created and executed root-level `validate.ps1`. Observed all stages pass: 12/12 tests, compliant fixture 0 denials, noncompliant fixture 4 denials, final output `ALL VALIDATION CHECKS PASSED.`
- Scope limits: these are local fixture/test results only. Hosted Actions remains blocked before job startup by the reported account billing lock; no cloud resources were deployed or changed. The unknown-ingress guard currently targets the explicit case where the entire ingress attribute is marked unknown; nested/partial unknown values require further review.

## Next actions
- [ ] Check the outcome of the retried GitHub Actions job and diagnose any runner/provisioning issue.
- [x] Run `opa version` and `opa test policy -v` locally on OPA 1.21.4; 12/12 tests pass.
- [x] Verify compliant fixture yields zero violations (observed 0).
- [x] Verify noncompliant fixture yields four expected violations and inspect emitted messages.
- [ ] Review unknown plan values, missing controls, replacement actions, and module resources.
- [x] Add tests for IPv6 ingress, RDP, all four S3 public-access settings, and explicit unknown ingress; 12/12 tests pass.
- [x] Record sanitized local outputs and observed results in this log.

## Results ledger
| Check | Expected | Observed |
|---|---|---|
| Fixture JSON parsing | Both valid | PASS — Python JSON parser |
| OPA unit tests | Pass | PASS — 12/12 on OPA 1.21.4, Windows/amd64 |
| Compliant fixture | 0 violations | PASS — observed `0` |
| Noncompliant fixture | 1+ violations | PASS — observed `4`; SSH, RDP, EBS encryption, and S3 public-access protection violations displayed |
| GitHub Actions | Green | BLOCKED — GitHub UI reports account locked due to a billing issue; workflow job did not start |
| Local validation script | All checks pass | PASS — `validate.ps1`: 12/12 tests; compliant 0 denials; noncompliant 4 denials |
| Cloud deployment | Not required | Not performed |

## Evidence entry template
- Date/time and timezone
- Exact command and tool version
- Pass/fail result
- Sanitized output or URL
- Commit SHA
- Limitations and next action


### 2026-10-23 — Step 7: Terraform AWS-provider plan integration and unknown-ingress regression

#### Purpose
Validate the policy against real Terraform-generated plan JSON, not only hand-authored fixtures. The specific issue was that AWS provider plan metadata can report `change.after_unknown.ingress == true` for a security group whose configuration omits ingress entirely. Treating every such plan as unresolved exposure produced a false positive for a no-ingress compliant configuration. Conversely, simply suppressing the rule whenever configuration metadata was present would weaken the intended fail-closed behavior for explicitly configured but unresolved ingress.

#### Tooling and safety boundary
- Terraform CLI observed in the local environment: **1.17.0**.
- AWS provider used for isolated plan generation: **hashicorp/aws v6.70.0**.
- OPA CLI: **1.21.4**, Rego v1, Windows/amd64.
- Tests were run from the downloaded project folder at `C:\Users\Administrator\Downloads\zero-trust-policy-as-code-main (1)\zero-trust-policy-as-code-main`.
- The isolated integration fixture directory was `aws-policy-test\`; it was not a deployment of the portfolio's infrastructure.
- Dummy AWS credentials and a placeholder VPC ID were used to produce plans. Commands stopped at `terraform plan` / JSON inspection and OPA evaluation. **No `terraform apply` was run; no AWS infrastructure was deployed or modified.**
- Generated plan JSON files included `aws-policy-test\tplan.json`, `aws-policy-test\tplan-rdp.json`, and `aws-policy-test\compliant-test\compliant.json`. These are local test artifacts and are not assumed to be committed to the repository.

#### Reproduction and evidence
1. **Public SSH case:** generated a Terraform plan containing a security group whose ingress exposes TCP/22 to `0.0.0.0/0`. Evaluating the JSON with OPA returned:
   `SSH (TCP/22) exposed to the public internet: aws_security_group.public_ssh_test`
2. **Public RDP case:** generated a plan containing a security group whose ingress exposes TCP/3389 to `0.0.0.0/0`. OPA returned:
   `RDP (TCP/3389) exposed to the public internet: aws_security_group.public_rdp_test`
3. **Compliant no-ingress case:** generated a plan for a security group with no ingress block. The plan JSON showed `input.configuration.root_module.resources[0].expressions` contained no `ingress` expression, although provider plan metadata marked `after_unknown.ingress` as true. The intended OPA result was `[]` (zero violations), and that was observed after the policy change.
4. The tests were plan-only. These checks validate the named resource patterns and provider behavior in this isolated fixture; they do not prove all AWS provider versions or every possible Terraform module/resource shape.

#### Policy adjustment
The unresolved-ingress logic now distinguishes two cases:
- If `after_unknown.ingress` is true and root-module configuration resource metadata is unavailable/not an array, deny rather than assume safety.
- If configuration metadata is present, deny when the matching root-module resource has an explicit `expressions.ingress` entry, while allowing the tested case where the ingress expression is absent because ingress was omitted from configuration.

The existing synthetic regression test has no `configuration` object, so it continues to exercise the fail-closed branch. The real-provider compliant plan exercises the provider-specific omitted-ingress case.

**Known limitation requiring follow-up:** this implementation searches `configuration.root_module.resources` for a matching resource address. Terraform configurations with nested child modules may place resource expressions in nested module configuration, so recursive module traversal and partial/nested unknown values have not yet been demonstrated. Do not describe this as complete handling of all unknown Terraform plan values. The rule is a targeted mitigation for the observed provider behavior, with fail-closed handling when root configuration resource metadata is absent.

#### Exact OPA evaluation commands used
From the project root, the SSH plan was evaluated with:
```powershell
& "$HOME\Tools\OPA\opa.exe" eval --format pretty --data .\policy --input .\aws-policy-test\tplan.json 'data.terraform.guardrails.violations'
```

The RDP plan was evaluated with:
```powershell
& "$HOME\Tools\OPA\opa.exe" eval --format pretty --data .\policy --input .\aws-policy-test\tplan-rdp.json 'data.terraform.guardrails.violations'
```

The compliant plan was evaluated with:
```powershell
& "$HOME\Tools\OPA\opa.exe" eval --format pretty --data .\policy --input .\aws-policy-test\compliant-test\compliant.json 'data.terraform.guardrails.violations'
```

Observed outcomes:
- Public SSH fixture: **one SSH exposure denial**.
- Public RDP fixture: **one RDP exposure denial**.
- Compliant security group with no ingress expression: **empty result `[]`**.

#### Regression encountered and correction
- First attempted implementation only considered configured ingress. It regressed the synthetic unknown-ingress test because that test intentionally omits Terraform configuration metadata. Result: **11/12 tests passed**.
- Corrected the rule into separate fail-closed and configuration-aware branches. This restored the synthetic regression case while addressing the real AWS provider false positive.
- Re-ran `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\validate.ps1"` from the project root. Observed:
  - `[1/3] Running policy tests...`
  - `PASS: 12/12`
  - `[2/3] Checking compliant fixture...`
  - `PASS: compliant fixture produced 0 denials.`
  - `[3/3] Checking noncompliant fixture...`
  - `PASS: noncompliant fixture produced 4 denials.`
  - `ALL VALIDATION CHECKS PASSED.`

#### Git and source-control handling
The local working directory was a ZIP-extracted folder, not a Git working tree: `git status --short` returned `fatal: not a git repository`, and a parent-directory check found no `.git` or `.gitignore`. No `git init` was run. The source changes are being applied through the GitHub repository workflow on a dedicated branch so the ZIP folder is not mistaken for a clone and the default branch is not silently overwritten.

#### Evidence classification
- **Implemented in the branch:** targeted unresolved-ingress policy change.
- **Locally tested:** 12/12 Rego tests; compliant example 0 denials; noncompliant example 4 denials; `validate.ps1` completed all stages.
- **Observed against real Terraform-generated plans:** public SSH denied; public RDP denied; no-ingress compliant security group returned no violations.
- **Not verified:** hosted Actions green status; full recursive module handling; every provider/version/resource schema; complete Zero Trust coverage; production deployment; complete NIST SP 800-207 conformance.

### 2026-10-23 — Step 8: Main-branch provider regression coverage
- Applied the provider-aware unknown-ingress policy and the associated README scope note directly to `main`.
- Added two Rego regression tests to `policy/guardrails_test.rego`: (1) provider marks ingress unknown while root configuration omits an ingress expression, which should remain allowed; (2) provider marks ingress unknown while the matching configuration explicitly contains an ingress expression, which should be denied.
- These two new tests are committed to `main`, but **have not been executed in this GitHub-connected session**. The previously observed 12/12 local test result predates these two additions. Re-run `opa test policy -v` and `.\validate.ps1` from a real clone before treating the expanded 14-test suite as passing.
- The prior Terraform AWS provider plan observations remain limited to the isolated local test fixtures documented in Step 7. No cloud apply or deployment was performed.


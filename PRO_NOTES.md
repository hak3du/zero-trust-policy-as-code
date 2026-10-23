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

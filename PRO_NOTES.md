# Professional Engineering Notes — Zero Trust Policy-as-Code

Maintain this as the authoritative, factual build log. Distinguish implemented, tested, observed, and unverified. Record commands, tool versions, output, failures, fixes, commit SHAs, and evidence URLs.

## Project control
- Project: Terraform + OPA/Rego infrastructure guardrails
- Repository: https://github.com/hak3du/zero-trust-policy-as-code
- Status: Initial source files being published; runtime tests and hosted CI are pending.
- No cloud infrastructure has been deployed or changed.
- Never claim passing tests, measured impact, NIST conformance, or production deployment without evidence.

## Engineering log

### 2026-10-22 — Step 1: Scope
Decision: this project must live in its own repository, independent of `hak3du/portfolio`.

Acceptance criteria:
1. OPA evaluates Terraform plan JSON.
2. Selected risky SSH/RDP exposure, unencrypted EBS, and disabled S3 public-access settings produce violations.
3. Unit tests cover positive and negative cases.
4. Compliant fixture returns zero violations.
5. Noncompliant fixture returns one or more violations.
6. CI runs tests and fixture checks.
7. Every material step and result is logged here.

### 2026-10-22 — Step 2: Initial source package
Prepared policy, unit tests, two plan fixtures, local test script, Makefile, README, and CI workflow as a standalone repository layout.

Status: source authored; execution not yet verified.

### 2026-10-23 — Step 3: New repository created and files published
Confirmed the target repository exists and is public; default branch is `main`; connected GitHub permissions report push access. Initial files are being committed to `main` individually through the GitHub contents API.

Validation status at this step: file publication is not equivalent to test success. OPA execution and GitHub Actions results remain pending until observed.

## Next actions
- [ ] Confirm all expected files exist on `main`.
- [ ] Record OPA version and run `opa test policy -v`.
- [ ] Verify compliant fixture yields zero violations.
- [ ] Verify noncompliant fixture yields expected violations.
- [ ] Link the real GitHub Actions run and record its status.
- [ ] Review unknown plan values, missing controls, replacement actions, and module resources.
- [ ] Add tests for fixes and capture sanitized evidence.

## Results ledger
| Check | Expected | Observed |
|---|---|---|
| OPA unit tests | Pass | Pending |
| Compliant fixture | 0 violations | Pending |
| Noncompliant fixture | 1+ violations | Pending |
| GitHub Actions | Green | Pending |
| Cloud deployment | Not required | Not performed |

## Evidence entry template
- Date/time and timezone
- Exact command and tool version
- Pass/fail result
- Sanitized output or URL
- Commit SHA
- Limitations and next action

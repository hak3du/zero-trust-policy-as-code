# Professional Engineering Notes — Zero Trust Policy-as-Code

This is the authoritative factual build log. Distinguish implemented, tested, observed, and unverified. Record commands, tool versions, output, failures, fixes, commit SHAs, and evidence URLs.

## Project control
- Project: Terraform + OPA/Rego infrastructure guardrails
- Repository: https://github.com/hak3du/zero-trust-policy-as-code
- Status: Source files published to `main`; runtime policy tests are unverified; GitHub Actions has failed before exposing job steps.
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
- The local runtime does not have the `opa` executable installed. No local OPA test or policy evaluation has been performed.
- GitHub Actions run 1: https://github.com/hak3du/zero-trust-policy-as-code/actions/runs/39964973624 — reported `failure`, completed about two seconds after start, with no job steps exposed.
- GitHub Actions run 2: https://github.com/hak3du/zero-trust-policy-as-code/actions/runs/39964974324 — reported `failure`, completed about two seconds after start, with no job steps exposed.
- GitHub Actions run 3: https://github.com/hak3du/zero-trust-policy-as-code/actions/runs/39965095970 — reported `failure`, completed about two seconds after start, with no job steps exposed.
- Log retrieval returned GitHub `404 BlobNotFound`; job-step retrieval returned an empty step list. Root cause is **undetermined**; do not attribute failure to policy syntax without evidence.
- Checked the official Open Policy Agent setup action documentation. The workflow's `open-policy-agent/setup-opa@v2` reference and `version: latest` input match the documented usage: https://github.com/open-policy-agent/setup-opa#readme . This does not explain the zero-step failure.
- Retried the failed GitHub Actions job once through GitHub's rerun-job operation. The retry also failed. The new job ID was `120453705402`; step retrieval returned an empty list and log retrieval returned `404 BlobNotFound`. This reinforces that no runner steps/logs were exposed; the underlying cause remains unknown.
- Adjusted workflow triggers to run only when policy, fixture, or workflow files change, avoiding unnecessary runs for notes-only commits. Workflow change commit: `ca8b69b98bc0cafef41b4ba9cfcf5415218f352c`.
- CI is not green; policy behavior remains unverified.

## Next actions
- [ ] Check the outcome of the retried GitHub Actions job and diagnose any runner/provisioning issue.
- [ ] Run `opa version` and `opa test policy -v` in a working OPA 1.x environment.
- [ ] Verify compliant fixture yields zero violations.
- [ ] Verify noncompliant fixture yields expected violations and inspect emitted messages.
- [ ] Review unknown plan values, missing controls, replacement actions, and module resources.
- [ ] Add tests for IPv6 ingress, RDP, all S3 public-access settings, and policy edge cases.
- [ ] Capture sanitized output and update this log with observed results.

## Results ledger
| Check | Expected | Observed |
|---|---|---|
| Fixture JSON parsing | Both valid | PASS — Python JSON parser |
| OPA unit tests | Pass | NOT RUN — OPA unavailable locally |
| Compliant fixture | 0 violations | Pending |
| Noncompliant fixture | 1+ violations | Pending |
| GitHub Actions | Green | FAIL — three original runs plus one retry; all observed job attempts expose no steps/logs; root cause unknown |
| Cloud deployment | Not required | Not performed |

## Evidence entry template
- Date/time and timezone
- Exact command and tool version
- Pass/fail result
- Sanitized output or URL
- Commit SHA
- Limitations and next action

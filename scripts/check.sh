#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v opa >/dev/null || { echo "Install OPA CLI 1.x first."; exit 127; }
opa version
opa test policy -v
safe="$(opa eval --format raw --data policy --input examples/compliant-plan.json 'count(data.terraform.guardrails.deny)')"
echo "Compliant fixture violations: $safe"
test "$safe" = "0"
unsafe="$(opa eval --format raw --data policy --input examples/noncompliant-plan.json 'count(data.terraform.guardrails.deny)')"
echo "Noncompliant fixture violations: $unsafe"
test "$unsafe" -ge "1"
opa eval --format pretty --data policy --input examples/noncompliant-plan.json 'data.terraform.guardrails.violations'
echo "PASS: checks behaved as expected."

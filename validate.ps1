$ErrorActionPreference = "Stop"

$OPA = "$HOME\Tools\OPA\opa.exe"

if (-not (Test-Path $OPA)) {
    throw "OPA not found at $OPA"
}

Write-Host "`n[1/3] Running policy tests..." -ForegroundColor Cyan
& $OPA test policy -v
if ($LASTEXITCODE -ne 0) {
    throw "Policy tests failed."
}

Write-Host "`n[2/3] Checking compliant fixture..." -ForegroundColor Cyan
$compliant = & $OPA eval --format raw --data policy --input examples/compliant-plan.json "count(data.terraform.guardrails.deny)"
if ($LASTEXITCODE -ne 0) {
    throw "Compliant fixture evaluation failed."
}
if ($compliant.Trim() -ne "0") {
    throw "Compliant fixture unexpectedly produced $($compliant.Trim()) denials."
}
Write-Host "PASS: compliant fixture produced 0 denials." -ForegroundColor Green

Write-Host "`n[3/3] Checking noncompliant fixture..." -ForegroundColor Cyan
$noncompliant = & $OPA eval --format raw --data policy --input examples/noncompliant-plan.json "count(data.terraform.guardrails.deny)"
if ($LASTEXITCODE -ne 0) {
    throw "Noncompliant fixture evaluation failed."
}
if ([int]$noncompliant.Trim() -lt 1) {
    throw "Noncompliant fixture unexpectedly passed."
}
Write-Host "PASS: noncompliant fixture produced $($noncompliant.Trim()) denials." -ForegroundColor Green

Write-Host "`nALL VALIDATION CHECKS PASSED." -ForegroundColor Green

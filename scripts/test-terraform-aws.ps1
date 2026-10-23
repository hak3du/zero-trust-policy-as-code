[CmdletBinding()]
param(
    [string]$TerraformPath = "terraform",
    [string]$OpaPath = "opa"
)
$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$policyDir = Join-Path $repoRoot "policy"
$integrationRoot = Join-Path $repoRoot "terraform-integration"
$artifactRoot = Join-Path $repoRoot "artifacts\terraform-aws"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

if ($TerraformPath -eq "terraform") {
    if (-not (Get-Command $TerraformPath -ErrorAction SilentlyContinue)) { throw "Terraform CLI not found; pass -TerraformPath with the executable path." }
} elseif (-not (Test-Path $TerraformPath)) { throw "Terraform executable not found: $TerraformPath" }
if ($OpaPath -eq "opa") {
    if (-not (Get-Command $OpaPath -ErrorAction SilentlyContinue)) { throw "OPA CLI not found; pass -OpaPath with the executable path." }
} elseif (-not (Test-Path $OpaPath)) { throw "OPA executable not found: $OpaPath" }

# Force dummy credentials to avoid accidentally using a real AWS identity.
$env:AWS_ACCESS_KEY_ID = "integration-test"
$env:AWS_SECRET_ACCESS_KEY = "integration-test-secret"
$env:AWS_SESSION_TOKEN = "integration-test-session"
$env:AWS_EC2_METADATA_DISABLED = "true"
$env:AWS_DEFAULT_REGION = "us-east-1"
$env:AWS_REGION = "us-east-1"

$cases = @(
    @{ Name = "public-ssh"; Expected = 1 },
    @{ Name = "public-rdp"; Expected = 1 },
    @{ Name = "compliant-no-ingress"; Expected = 0 }
)
$failures = 0
foreach ($case in $cases) {
    $caseDir = Join-Path $integrationRoot $case.Name
    $planPath = Join-Path $artifactRoot "$($case.Name).tfplan"
    $jsonPath = Join-Path $artifactRoot "$($case.Name).json"
    Write-Host "`n=== Terraform/AWS integration: $($case.Name) ===" -ForegroundColor Cyan
    & $TerraformPath -chdir="$caseDir" init -backend=false -input=false
    if ($LASTEXITCODE -ne 0) { throw "Terraform init failed for $($case.Name)" }
    & $TerraformPath -chdir="$caseDir" plan -refresh=false -input=false -lock=false -out="$planPath"
    if ($LASTEXITCODE -ne 0) { throw "Terraform plan failed for $($case.Name)" }
    $json = & $TerraformPath -chdir="$caseDir" show -json "$planPath"
    if ($LASTEXITCODE -ne 0) { throw "Terraform show -json failed for $($case.Name)" }
    $json | Set-Content -LiteralPath $jsonPath -Encoding utf8
    $raw = & $OpaPath eval --format raw --data $policyDir --input $jsonPath "count(data.terraform.guardrails.deny)"
    if ($LASTEXITCODE -ne 0) { throw "OPA evaluation failed for $($case.Name)" }
    $actual = [int]($raw | Select-Object -Last 1)
    Write-Host "Expected denials: $($case.Expected)"
    Write-Host "Actual denials:   $actual"
    Write-Host "Plan JSON:        $jsonPath"
    if ($actual -ne $case.Expected) {
        Write-Host "FAIL" -ForegroundColor Red
        $failures++
    } else { Write-Host "PASS" -ForegroundColor Green }
}
if ($failures -gt 0) { throw "$failures Terraform/AWS integration case(s) failed." }
Write-Host "`nALL TERRAFORM/AWS INTEGRATION CHECKS PASSED." -ForegroundColor Green
Write-Host "Generated JSON is under artifacts\terraform-aws. Review before sharing."

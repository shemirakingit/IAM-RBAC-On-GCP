param(
    [Parameter(Mandatory)][string]$Project,
    [string]$Zone   = "us-central1-a",
    [string]$VMName = "fs01"
)

Write-Host "`nGCP IAM Lab - Pre-flight Checks" -ForegroundColor Cyan
$allPass = $true

$account = gcloud config get-value account 2>$null
Write-Host "Active account : $account"
Write-Host "Project        : $Project`n"

# 1. Required APIs
$enabled = gcloud services list --enabled --project $Project --format="value(config.name)"
$apis = @("compute.googleapis.com", "iam.googleapis.com", "iamcredentials.googleapis.com", "cloudresourcemanager.googleapis.com")
foreach ($api in $apis) {
    if ($enabled -contains $api) {
        Write-Host "  [PASS] API enabled: $api" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] API not enabled: $api  ->  gcloud services enable $api --project $Project" -ForegroundColor Red
        $allPass = $false
    }
}

# 2. fs01 exists and is running
$status = gcloud compute instances describe $VMName --zone $Zone --project $Project --format="value(status)" 2>$null
if ($status -eq "RUNNING") {
    Write-Host "  [PASS] $VMName is RUNNING in $Zone" -ForegroundColor Green
} elseif ($status) {
    Write-Host "  [WARN] $VMName status is $status (start it before testing)" -ForegroundColor Yellow
} else {
    Write-Host "  [FAIL] $VMName not found in $Zone - confirm Lab 1 is deployed and the zone matches" -ForegroundColor Red
    $allPass = $false
}

# 3. Application Default Credentials (what Terraform uses)
gcloud auth application-default print-access-token 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [PASS] Application Default Credentials found" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] No ADC - run: gcloud auth application-default login" -ForegroundColor Red
    $allPass = $false
}

if ($allPass) { Write-Host "`nReady to deploy." -ForegroundColor Green }
else { Write-Host "`nFix the failures above before running terraform." -ForegroundColor Red }

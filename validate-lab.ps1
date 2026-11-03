param(
    [Parameter(Mandatory)][string]$Project,
    [string]$Zone           = "us-central1-a",
    [string]$VMName         = "fs01",
    [string]$OperatorRoleId = "fileServerOperator"
)

Write-Host "`n=== GCP IAM Lab Validation ===" -ForegroundColor Cyan

# 1. Read the live IAM policy on fs01
$raw = gcloud compute instances get-iam-policy $VMName --zone $Zone --project $Project --format=json 2>$null
if ($LASTEXITCODE -ne 0 -or -not $raw) { throw "Could not read IAM policy for $VMName in $Project. Confirm Lab 1 is deployed." }
$policy = ($raw -join "`n") | ConvertFrom-Json
Write-Host "Scope: projects/$Project/zones/$Zone/instances/$VMName`n"

# 2. What we expect to find
$expected = @(
    @{ Label="SysAdmin";    Role="roles/compute.admin";                         Member="serviceAccount:iamlab-sysadmin@${Project}.iam.gserviceaccount.com" },
    @{ Label="SupportTech"; Role="projects/${Project}/roles/${OperatorRoleId}"; Member="serviceAccount:iamlab-supporttech@${Project}.iam.gserviceaccount.com" },
    @{ Label="Auditor";     Role="roles/compute.viewer";                        Member="serviceAccount:iamlab-auditor@${Project}.iam.gserviceaccount.com" }
)

$allPass = $true
Write-Host "[ Binding Validation on $VMName ]" -ForegroundColor White
foreach ($e in $expected) {
    $match = $policy.bindings | Where-Object { $_.role -eq $e.Role -and $_.members -contains $e.Member }
    if ($match) { Write-Host "  [PASS] $($e.Label): $($e.Role)" -ForegroundColor Green }
    else { Write-Host "  [FAIL] $($e.Label): $($e.Role) not bound to $($e.Member)" -ForegroundColor Red; $allPass = $false }
}

# 3. Blast-radius check: the personas must hold NO roles at project level
Write-Host "`n[ Scope Check - nothing granted at project level ]" -ForegroundColor White
$projRaw = gcloud projects get-iam-policy $Project --format=json 2>$null
$projPolicy = ($projRaw -join "`n") | ConvertFrom-Json
foreach ($e in $expected) {
    $leaks = $projPolicy.bindings | Where-Object { $_.members -contains $e.Member }
    if ($leaks) { Write-Host "  [FAIL] $($e.Label) holds project-level role(s): $($leaks.role -join ', ')" -ForegroundColor Red; $allPass = $false }
    else { Write-Host "  [PASS] $($e.Label) holds no project-level roles" -ForegroundColor Green }
}

# 4. Permission matrix
Write-Host "`n[ Permission Matrix - $VMName scope only ]" -ForegroundColor White
$matrix = @(
    @{ Action="View VM details";          A="Yes"; O="Yes"; V="Yes" },
    @{ Action="Start / stop / reset VM";  A="Yes"; O="Yes"; V="No"  },
    @{ Action="Change VM configuration";  A="Yes"; O="No";  V="No"  },
    @{ Action="Delete VM";                A="Yes"; O="No";  V="No"  },
    @{ Action="Change IAM on the VM";     A="Yes"; O="No";  V="No"  }
)
Write-Host ("  {0,-26} {1,-15} {2,-19} {3}" -f "Action","Compute Admin","File Srv Operator","Compute Viewer")
foreach ($row in $matrix) { Write-Host ("  {0,-26} {1,-15} {2,-19} {3}" -f $row.Action,$row.A,$row.O,$row.V) }

# 5. Export report
$overall = if ($allPass) { "ALL PASS" } else { "FAILURES DETECTED" }
$report  = "GCP IAM Lab Validation Report`r`nGenerated: $(Get-Date)`r`nScope: projects/$Project/zones/$Zone/instances/$VMName`r`n`r`n"
foreach ($b in $policy.bindings) { $report += "$($b.role)`r`n    $($b.members -join ', ')`r`n" }
$report += "`r`nOverall: $overall"
$report | Out-File "./IAM_Lab_Report.txt" -Encoding UTF8

Write-Host "`nReport exported: IAM_Lab_Report.txt" -ForegroundColor Cyan
Write-Host "Overall: $overall" -ForegroundColor $(if ($allPass) { "Green" } else { "Red" })

# GCP IAM Access Control Lab

Least-privilege access control for a Compute Engine VM on Google Cloud, deployed with Terraform and verified with PowerShell and `gcloud`.

Three personas hold three different roles on **one VM only**. A custom role gives the help desk "restart but never reconfigure or delete."

## What it builds

| Persona (service account) | Role on `fs01` | Can do | Cannot do |
|---|---|---|---|
| `iamlab-sysadmin` | `roles/compute.admin` | Everything on the VM, including its IAM policy | n/a |
| `iamlab-supporttech` | Custom: File Server Operator | Get, start, stop, reset | Reconfigure, delete, read or change IAM |
| `iamlab-auditor` | `roles/compute.viewer` | View VM details | Any action |

10 resources in total: 3 service accounts, 3 impersonation grants, 1 custom role, 3 instance-level IAM bindings.

## Design choices

- **Bindings on the instance, not the project.** Other VMs in the project are invisible to every persona.
- **Custom role with 4 permissions** (`compute.instances.get/start/stop/reset`), because no predefined role means "restart but never delete."
- **`google_compute_instance_iam_member`** is additive. It never replaces other bindings on the VM.
- **Service accounts + impersonation** make it possible to test each persona without extra Google accounts.
- **No defaults** on `project_id` and `tester_email`, so a careless apply can't target the wrong project.

## Prerequisites

- A GCP project with a running Compute Engine VM named `fs01` (lowercase) in `us-central1-a`. Change the variable defaults if yours differs.
- Terraform >= 1.5.0, Google Cloud CLI, PowerShell 7
- APIs enabled: `compute`, `iam`, `iamcredentials`, `cloudresourcemanager`
- A GCS bucket for Terraform state. Edit `backend.tf` with its name.

Cloud Shell no longer includes PowerShell or Terraform, so install both first, or run locally.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in project_id and tester_email
pwsh ./scripts/01-preflight.ps1 -Project YOUR_PROJECT_ID

terraform init
terraform plan          # expect: 10 to add
terraform apply

pwsh ./validate-lab.ps1 -Project YOUR_PROJECT_ID
```

`validate-lab.ps1` reads the live IAM policy on fs01, confirms all three bindings, checks that none of the personas hold roles at **project level**, prints a permission matrix and exports `IAM_Lab_Report.txt`.

## Testing as each persona

Run `gcloud` as each service account with `--impersonate-service-account`:

```powershell
gcloud compute instances describe fs01 --zone us-central1-a --project $P --impersonate-service-account=$AUDITOR
```

Results from my run:

| Command | Auditor | SupportTech | SysAdmin |
|---|---|---|---|
| describe fs01 | Allowed | n/a | Allowed |
| stop fs01 | Denied (403) | n/a | n/a |
| reset fs01 | n/a | Allowed | n/a |
| get-iam-policy fs01 | n/a | Denied (403) | Allowed |
| add-metadata fs01 | n/a | Denied (403) | n/a |
| describe dc01 (another VM) | Denied (403) | Denied (403) | n/a |

Delete is deliberately not tested: if a role were misconfigured, the test would destroy the VM.

## Teardown

```bash
terraform destroy
```

GCP soft-deletes custom roles. If you re-apply soon after destroying, undelete with `gcloud iam roles undelete fileServerOperator --project YOUR_PROJECT_ID` or set a new `operator_role_id`.

## Production notes

- Bind **groups**, not individual users.
- Avoid basic roles (Owner, Editor, Viewer); they apply project-wide.
- Add IAM Conditions for time-bound elevated access.
- Pair with a Cloud Audit Logs query for `SetIamPolicy` events.

## Part of a series

Lab 1: NTFS file server on GCP. Lab 2 (this repo): GCP IAM access control.

resource "google_service_account" "sysadmin" {
  account_id   = "iamlab-sysadmin"
  display_name = "IAM Lab - SysAdmin (Compute Admin on fs01)"
}

resource "google_service_account" "supporttech" {
  account_id   = "iamlab-supporttech"
  display_name = "IAM Lab - SupportTech (File Server Operator on fs01)"
}

resource "google_service_account" "auditor" {
  account_id   = "iamlab-auditor"
  display_name = "IAM Lab - Auditor (Compute Viewer on fs01)"
}

# Lets your account run gcloud AS each persona via --impersonate-service-account
resource "google_service_account_iam_member" "tester_can_impersonate" {
  for_each = {
    sysadmin    = google_service_account.sysadmin.name
    supporttech = google_service_account.supporttech.name
    auditor     = google_service_account.auditor.name
  }

  service_account_id = each.value
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:${var.tester_email}"
}

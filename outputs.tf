output "project_id" {
  value = data.google_project.lab.project_id
}

output "instance_self_link" {
  value       = data.google_compute_instance.fs01.self_link
  description = "The resource all three bindings are attached to."
}

output "persona_service_accounts" {
  description = "Use these with --impersonate-service-account in Step 6."
  value = {
    sysadmin    = google_service_account.sysadmin.email
    supporttech = google_service_account.supporttech.email
    auditor     = google_service_account.auditor.email
  }
}

output "iam_summary" {
  description = "Binding IDs - view with: terraform output -json iam_summary"
  value = {
    admin    = google_compute_instance_iam_member.sysadmin_admin.id
    operator = google_compute_instance_iam_member.supporttech_operator.id
    viewer   = google_compute_instance_iam_member.auditor_viewer.id
  }
}

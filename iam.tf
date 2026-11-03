# Custom role: the help desk needs to restart a hung server, nothing more.
resource "google_project_iam_custom_role" "file_server_operator" {
  role_id     = var.operator_role_id
  title       = "File Server Operator"
  description = "Get, start, stop and reset a VM. Cannot delete, reconfigure, or change IAM."
  stage       = "GA"
  permissions = [
    "compute.instances.get",
    "compute.instances.start",
    "compute.instances.stop",
    "compute.instances.reset",
  ]
}

# Compute Admin: full control of fs01 including its IAM policy.
resource "google_compute_instance_iam_member" "sysadmin_admin" {
  project       = var.project_id
  zone          = var.zone
  instance_name = data.google_compute_instance.fs01.name
  role          = "roles/compute.admin"
  member        = "serviceAccount:${google_service_account.sysadmin.email}"
}

# File Server Operator: get, start, stop, reset fs01.
resource "google_compute_instance_iam_member" "supporttech_operator" {
  project       = var.project_id
  zone          = var.zone
  instance_name = data.google_compute_instance.fs01.name
  role          = google_project_iam_custom_role.file_server_operator.id
  member        = "serviceAccount:${google_service_account.supporttech.email}"
}

# Compute Viewer: view configuration and status - no actions of any kind.
resource "google_compute_instance_iam_member" "auditor_viewer" {
  project       = var.project_id
  zone          = var.zone
  instance_name = data.google_compute_instance.fs01.name
  role          = "roles/compute.viewer"
  member        = "serviceAccount:${google_service_account.auditor.email}"
}

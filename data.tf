# Read the project - fails loudly if the ID is wrong or the API is off
data "google_project" "lab" {
  project_id = var.project_id
}

# Read fs01 by name - fails if Lab 1 is not deployed.
# The IAM bindings in iam.tf attach to THIS instance only.
data "google_compute_instance" "fs01" {
  name    = var.instance_name
  zone    = var.zone
  project = data.google_project.lab.project_id
}

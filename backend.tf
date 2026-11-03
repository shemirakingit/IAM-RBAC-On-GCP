terraform {
  backend "gcs" {
    bucket = "REPLACE_WITH_YOUR_STATE_BUCKET_NAME"
    prefix = "iam-lab"
  }
}

provider "google" {
  credentials = file("../credential.json")
  project     = var.project_id
  region      = var.region
}
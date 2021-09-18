variable "project_id" {
  description = "The project ID"
}

variable "region" {
  description = "The region where VPC is"
  default     = "europe-west1" # or  "us-west1"
}

variable "zones" {
  description = "The zone where VPC is"
  type        = list(any)
  default     = ["a", "b", "c"]
}

variable "network" {
  type = map(any)

  default = {
    "name"    = "k8s"
    "iprange" = "10.240.0.0/24"
    "prefix"  = "10.240.0"
  }
}

variable "number_of_controller" {
  default = 2
}

variable "number_of_worker" {
  default = 2
}

variable "kube_api_port" {
  default = "6443"
}
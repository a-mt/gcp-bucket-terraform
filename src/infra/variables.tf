# Declare variables that are used in the .tf files
variable "gcp_svc_key" {
  type = string
  description = "local path to your service account's JSON key"
}
variable "gcp_project" {
  type = string
  description = "project ID"
}
variable "gcp_region" {
  default = "europe-west"
  type = string
  description = "region"
}
variable "gcp_dns_zone" {
  type = string
  description = "name of your zone in Cloud DNS"
}

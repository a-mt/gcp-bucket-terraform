
# --- BUCKET

# Create a bucket
# see https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "website" {
  provider = google
  name = "${var.gcp_project}-static-website"  # has to be globally unique
  location = "EU"
}

# Upload index.html to the bucket
resource "google_storage_bucket_object" "static_site_index" {
  name = "index.html"  # name in the bucket
  source = "../website/index.html"  # local path
  bucket = google_storage_bucket.website.name
}

# Make the bucket's index.html publicly accessible
resource "google_storage_object_access_control" "public_index_rule" {
  object = google_storage_bucket_object.static_site_index.name
  bucket = google_storage_bucket.website.name
  role = "READER"
  entity = "allUsers"
}

# --- CDN

# Set the bucket as a CDN backend
resource "google_compute_backend_bucket" "website_backend" {
  name = "website-bucket"
  bucket_name = google_storage_bucket.website.name
  description = "Contains files for the website"
  enable_cdn = true
}

# --- DNS

# Reserve a static external IP address
resource "google_compute_global_address" "website_ip" {
  name = "website-loadbalancer-ip"
}

# Retrieve our DNS zone data
data "google_dns_managed_zone" "dns_zone" {
  name = var.gcp_dns_zone
}

# Add the reserved external IP address to our DNS zone
resource "google_dns_record_set" "website" {
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  type = "A"
  ttl = 300
  name = "website.${data.google_dns_managed_zone.dns_zone.dns_name}" # domain name
  rrdatas = [google_compute_global_address.website_ip.address]
}

# --- LOAD BALANCER

# Create ingress rule
resource "google_compute_url_map" "website" {
  name = "website-bucket-redirect"
  default_service = google_compute_backend_bucket.website_backend.self_link

  host_rule  {
    hosts = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name = "allpaths"
    default_service = google_compute_backend_bucket.website_backend.self_link
  }
}

# Create Load Balancer
resource "google_compute_target_http_proxy" "website" {
  name = "website-load-balancer"
  url_map = google_compute_url_map.website.self_link
}

# Link IP address to Load Balancer
resource "google_compute_global_forwarding_rule" "default" {
  name = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address = google_compute_global_address.website_ip.address
  ip_protocol = "TCP"
  port_range = "80"
  target = google_compute_target_http_proxy.website.self_link
}

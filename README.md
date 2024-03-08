
Use terraform to upload index.html to a GCP bucket, and serve it using cloud DNS / cloud CDN / load balancer  
[Tutorial: Learn Terraform with Google Cloud Platform](https://www.youtube.com/watch?v=VCayKl82Lt8&pp=ygUWZnJlZWNvZGVjYW1wIHRlcnJhZm9ybQ%3D%3D)

## GCP setup

### Setup your GCP project

* Activate a Billing account

* Create a new project on GCP

  ```
  testing-terraform-416615
  ```

* Activate the following PAIs:

  - Cloud DNS API
  - Compute Engine API
  - IAM API

### Create a GCP service account

* Create a [service account](https://console.cloud.google.com/iam-admin/serviceaccounts)  
  Since we'll be using terraform to deploy our infrastructure, it needs a way to authenticate to google cloud to deploy the infrastructure

  ```
  terraform@testing-terraform-416615.iam.gserviceaccount.com
  ```

* Create a key for this service account:  
  Go to the service account details > keys > add key > JSON  

## Setup your Domain name

* Buy your domain name on namecheap or other

* Go to [Cloud DNS](https://console.cloud.google.com/net-services/dns/zones) > create zone

* In zone details: expand the routing policy of the line with the "NS" type  
  This will list the nameservers associated to our zone

  ```
  ns-cloud-d1.googledomains.com.
  ns-cloud-d2.googledomains.com.
  ns-cloud-d3.googledomains.com.
  ns-cloud-d4.googledomains.com. 
  ```

* On namecheap: Domain > Nameservers > Custom DNS  
  Update the nameservers with Google's nameservers (and save)

* Update infra/terraform.tfvars: gcp_dns_zone

## Install terraform locally

* Check if terraform is installed:

  ``` bash
  $ terraform --version
  Terraform v1.7.4
  on linux_amd64

  $ terraform -help
  ```

  If it is, skip to the next section

* Check if your distro is amongst the [supported distributions](https://www.hashicorp.com/official-packaging-guide?ajs_aid=b55b19b1-c3c9-47fa-ac93-6a1d93be9e0d&product_intent=terraform)

  ``` bash
  # Get distribution name
  $ lsb_release -cs

  $ DISTRO=focal
  ```

* [Install terraform](https://developer.hashicorp.com/terraform/install)

  ``` bash
  # Add the hashicorp repo to APT
  $ sudo su
  $ wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

  # Install terraform
  $ echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $DISTRO main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  $ sudo apt update && sudo apt install terraform
  ```

## Deploy on GCP using Terraform

* Install the dependencies

  ```
  $ cd src/infra
  $ terraform init
  ```

* Create infra/dev.terraform.tfvars

  ```
  gcp_svc_key = "../../testing-terraform-416615-d94fa54ce003.json"
  gcp_project = "testing-terraform-416615"
  gcp_region = "europe-west"
  gcp_dns_zone = "mydomainname"
  ```

* Check what terraform intends to do

  ```
  $ terraform plan -var-file=dev.terraform.tfvars
  ```

* Launch it

  ```
  $ terraform apply -var-file=dev.terraform.tfvars
  ```

* Check that the resources were created:

  - [Cloud storage > buckets](https://console.cloud.google.com/storage/browser)  
    Copy the public URL of index.html and visit it

  - Network Services > Load Balancing:  
    there's a new load balancer

  - Network Services > Cloud CDN:  
    there's a new caching rule

  - Network Services > Cloud DNS:  
    there's a new A entry in your DNS zone  
    You can access http://YOUR_IP/index.html  
    and http://website.YOUR_DOMAIN/index.html

## Clean up

```
$ terraform destroy -var-file=dev.terraform.tfvars
```

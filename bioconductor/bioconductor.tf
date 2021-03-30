

terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
  required_version = ">= 0.13"
}

provider "openstack" {
	token       = var.token
	auth_url    = "https://identity.cloud.muni.cz/v3"
	region      = "brno1"
    allow_reauth = false
}


resource "openstack_compute_instance_v2" "terraform_bio" {
	name = var.instance_name
	image_name = "debian-9-x86_64_bioconductor"
	flavor_name = "standard.2core-16ram"
	key_pair = var.ssh
    user_data = file("./cloud-init-bioconductor-image.sh")
    network {
        uuid = var.local_network_id
    }   
    metadata = {
        Bioclass_user = var.user_email
        Bioclass_email = var.user_name
    }
}	

resource "openstack_compute_floatingip_associate_v2" "test-server-fip-1" {
	floating_ip = var.floating_ip
	instance_id = openstack_compute_instance_v2.terraform_bio.id
}




terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
    http = {}
  }
  required_version = ">= 0.13"
}

provider "openstack" {
	token       = var.token
	auth_url    = "https://identity.cloud.muni.cz/v3"
	region      = "brno1"
    allow_reauth = false
}

data "http" "bioconductor_init" {
  url = "https://raw.githubusercontent.com/bio-platform/bio-class-deb10/main/install/cloud-init-bioconductor-image.sh"
}

resource "openstack_networking_secgroup_v2" "bioconductor_security_group" {
  name        = "bioconductor_security_group"
  description = "My bioconductor security group"
}

resource "openstack_networking_secgroup_rule_v2" "shh_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.bioconductor_security_group.id}"
}


resource "openstack_compute_instance_v2" "terraform_bio" {
	name = var.instance_name
	image_name = "debian-10-x86_64_bioconductor"
	flavor_name = "standard.2core-16ram"
	key_pair = var.ssh
    user_data = data.http.bioconductor_init.body
    network {
        uuid = var.local_network_id
    }   
    metadata = {
        Bioclass_user = var.user_name
        Bioclass_email = var.user_email
        name = "bioconductor"
        workspace_id = var.workspace_id
    }
}	

resource "openstack_networking_floatingip_v2" "floating_ip" {
  pool = "public-cesnet-78-128-250-PERSONAL"
  count = var.floating_ip == "default" ? 1 : 0
  lifecycle {
    prevent_destroy = true 
  }
}

resource "openstack_compute_floatingip_associate_v2" "bioconductor_fip" {
	floating_ip = var.floating_ip == "default" ? "${openstack_networking_floatingip_v2.floating_ip[0].address}" : var.floating_ip
	instance_id = openstack_compute_instance_v2.terraform_bio.id
}



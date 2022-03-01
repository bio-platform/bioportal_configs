terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
  required_version = ">= 0.13"
}

provider "openstack" {
	token = var.token
	auth_url    = "https://identity.cloud.muni.cz/v3"
	region      = "brno1"
	allow_reauth = false
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

resource "openstack_compute_instance_v2" "terra_ubuntu" {
	name = var.instance_name
	image_name = "ubuntu-focal-x86_64"
	flavor_name = var.flavor
	key_pair = var.ssh

    network {
        uuid = var.local_network_id
    } 
    metadata = {
        name = "ubuntu"
	    workspace_id = var.workspace_id
    }   
    security_groups = ["${openstack_networking_secgroup_v2.bioconductor_security_group.id}"]
}

resource "openstack_networking_floatingip_v2" "floating_ip" {
  pool = "public-cesnet-78-128-250-PERSONAL"
  count = var.floating_ip == "default" ? 1 : 0
  lifecycle {
    prevent_destroy = true 
  }
}

resource "openstack_compute_floatingip_associate_v2" "ubuntu_fip" {
	floating_ip = var.floating_ip == "default" ? "${openstack_networking_floatingip_v2.floating_ip[0].address}" : var.floating_ip
	instance_id = openstack_compute_instance_v2.terra_ubuntu.id
}

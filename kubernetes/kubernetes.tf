# Configure the OpenStack Provider
provider "openstack" {
        token       = var.token
        auth_url    = "https://identity.cloud.muni.cz/v3"
        region      = "brno1"
    allow_reauth = false
}

terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
    }
  }
  required_version = ">= 0.13"
}

data "openstack_images_image_v2" "debian11" {
  name = "debian-11-x86_64"
}

data "openstack_compute_flavor_v2" "flavor" {
  name = "standard.medium"
}

data "openstack_compute_keypair_v2" "user" {
  name = var.ssh
}

resource "openstack_compute_keypair_v2" "kubernetes" {
  name = "tf kubernetes keypair"
}

data "template_file" "cloud_config" {
  template = file("./files/cloud-config")
  vars = {
    user_key = data.openstack_compute_keypair_v2.user.public_key
    kubernetes_key = openstack_compute_keypair_v2.kubernetes.public_key
    kubernetes_privkey = openstack_compute_keypair_v2.kubernetes.private_key
  }
}

data "template_cloudinit_config" "config" {
  base64_encode = true
  part {
    content = data.template_file.cloud_config.rendered
  }
}

resource "openstack_networking_secgroup_v2" "secgroup" {
  name        = "sg kubernetes"
  description = "terraform kubernetes security group"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_compute_instance_v2" "node" {
  name            = "kube-node"
  image_id        = data.openstack_images_image_v2.debian11.id
  flavor_id       = data.openstack_compute_flavor_v2.flavor.id
  security_groups = [ openstack_networking_secgroup_v2.secgroup.name ]
  key_pair        = openstack_compute_keypair_v2.kubernetes.name
  count           = var.n
  user_data       = data.template_cloudinit_config.config.rendered
  network {
    uuid = var.local_network_id
  }
  metadata = {
    name = "kubernetes"
    workspace_id = var.workspace_id
  }
}

resource "openstack_compute_instance_v2" "master" {
  name            = "kube-master"
  image_id        = data.openstack_images_image_v2.debian11.id
  flavor_id       = data.openstack_compute_flavor_v2.flavor.id
  security_groups = [ openstack_networking_secgroup_v2.secgroup.name ]
  key_pair        = "tf kubernetes keypair"
  user_data       = data.template_cloudinit_config.config.rendered
  metadata = {
    kubenodes = join(" ", openstack_compute_instance_v2.node[*].access_ip_v4)
    name = "kubernetes"
    workspace_id = var.workspace_id
  }
  network {
    uuid = var.local_network_id
  }
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
	instance_id = openstack_compute_instance_v2.master.id
}
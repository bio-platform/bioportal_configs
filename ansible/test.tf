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

resource "openstack_compute_keypair_v2" "localkey" {
	name = join("", ["temp_key", uuid()])
}

resource "local_file" "localkey_f" {
	filename = openstack_compute_keypair_v2.localkey.name
	file_permission = "0600"
	sensitive_content = openstack_compute_keypair_v2.localkey.private_key
}

resource "openstack_compute_instance_v2" "terraform_ansible" {
	name = var.instance_name
	image_name = "ubuntu-focal-x86_64"
	flavor_name = var.flavor
	key_pair = var.ssh
    user_data = <<EOT
#cloud-config

users:
  - default
  - name: deployadm
    gecos: Deploy Admin
    shell: /bin/bash
    ssh_authorized_keys:
      - ${openstack_compute_keypair_v2.localkey.public_key}
    sudo:
      - ALL=(ALL) NOPASSWD:ALL

EOT
    network {
        uuid = var.local_network_id
    }
}

resource "openstack_compute_floatingip_associate_v2" "ubuntu_fip" {
	floating_ip = var.floating_ip
	instance_id = openstack_compute_instance_v2.terraform_ansible.id


    provisioner "remote-exec" {
        inline = ["sudo apt install python3"]
        connection {
            type = "ssh"
            user        = "deployadm"
            private_key = openstack_compute_keypair_v2.localkey.private_key
            host = var.floating_ip
        } 
    }

    provisioner "local-exec" {
        command =  <<EOF
pip3 install ansible
ansible-playbook  -u deployadm -i '${self.floating_ip},' --private-key openstack_compute_keypair_v2.localkey.name --ssh-extra-args='-o StrictHostKeyChecking=no' playbook.yml
EOF
    }
}




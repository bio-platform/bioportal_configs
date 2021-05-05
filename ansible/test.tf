terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
  required_version = ">= 0.13"
}

provider "openstack" {
	application_credential_id = "6f2bd352f056400baf71d97fc3ebb1f0"
	application_credential_secret = "xrBr0537QgwXTFAEMpiUTE6WzEBpNtYNUnJ3jzgsaDoI-6f2zfyZuyImpqZTFVDe9KJ_9iBcLDsOLwbGcV6fHw"
	auth_url    = "https://identity.cloud.muni.cz/v3"
	region      = "brno1"
	#endpoint_overrides = {
	#	"compute" = "https://compute.cloud.muni.cz/v2.1"
	#}
}

resource "openstack_compute_keypair_v2" "localkey" {
	name = "temp_key"
}

resource "local_file" "localkey_f" {
	filename = "temp_key"
	file_permission = "0600"
	sensitive_content = openstack_compute_keypair_v2.localkey.private_key
}

resource "openstack_compute_instance_v2" "terraform_bio" {
	name = "terraform_bio1"
	image_name = "ubuntu-focal-x86_64"
	flavor_name = "standard.medium"
	key_pair = "zenbook mint"
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
        uuid = "03b21c24-910f-4ec5-a8f3-419db219b383"
    }
}

resource "openstack_compute_floatingip_associate_v2" "ubuntu_fip" {
	floating_ip = "78.128.250.94"
	instance_id = openstack_compute_instance_v2.terraform_bio.id


    provisioner "remote-exec" {
        inline = ["sudo apt install python3"]
        connection {
            type = "ssh"
            user        = "deployadm"
            private_key = openstack_compute_keypair_v2.localkey.private_key
            host = "78.128.250.94"
        } 
    }

    provisioner "local-exec" {
        command =  <<EOF
pip3 install ansible
ansible-playbook  -u deployadm -i '${self.floating_ip},' --private-key temp_key --ssh-extra-args='-o StrictHostKeyChecking=no' playbook.yml
EOF
    }
}




variable "instance_name" {
  type = string
  default = "default"
}

variable "ssh" {
  type = string
  default = "default"
}

variable "local_network_id" {
  type = string
  default = "default"
}

variable "floating_ip" {
  type = string  
  default = "default"
}

variable "token" {
  type = string
}

variable "flavor" {
    type = string
    default = "default"
}

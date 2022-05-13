variable "token" {
  type = string
}
variable "ssh" {
  type = string
  default = "default"
}
variable "n" {
	description = "Number of instances"
	default = 2
}

variable "floating_ip" {
  type = string  
  default = "default"
}
variable "local_network_id" {
  type = string
  default = "default"
}
variable "workspace_id"{
  type = string 
}
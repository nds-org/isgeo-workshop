variable "env_name" {
  default = "kubeadm"
}

variable "pubkey" {
  default = "~/.ssh/id_rsa.pub"
}

variable "privkey" {
  default = "~/.ssh/id_rsa"
}

variable "master_flavor" {
  default = "m1.medium"
}

variable "image" {
  default = "Ubuntu 16.04 LTS"
}

variable "worker_flavor" {
  default = "m1.medium"
}

variable "storage_flavor" {
  default = "m1.medium"
}

variable "external_gateway" {
  default = "865ff018-8894-40c2-99b7-d9f8701ddb0b"
}

variable "public_network" {
  default = "public"
}

variable "availability_zone" {
  default = ""
}

variable "worker_count" {
  default = "1"
}

variable "worker_ips_count" {
  default = "1"
}

variable "docker_volume_size" {
  default = "50"
}

variable "storage_node_count" {
  default = "1"
}

variable "storage_node_volume_size" {
  default = "50"
}

variable "dns_nameservers" {
  description = "An array of DNS name server names used by hosts in this subnet."
  type        = "list"
  default     = ["8.8.8.8", "8.8.4.4"]
}

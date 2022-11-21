variable "name" {}

variable "rg" {}

variable "subnet_id" {}

variable "admin_username" {
  default = null
  type = string
}

variable "public_access" {
  default = false
  type = bool
}

variable "host_count" {
  type = number
  default = 1
}

variable "size" {
  default = "Standard_B1s"
}

variable "source_image_reference" {
  default = null
}

variable "os_disk_size_gb" {
  default = 127
}

variable "source_image_id" {
  default = null
}

variable "plan" {
  default = null
}

variable "extra_disks" {
  default = {}
}

variable "ingress_rules" {
  default = {}
}

variable "tags" {
  default = {}
}

variable "high_availability" {
  type = bool
  default = false
}

variable "boot_diagnostics_storage_account" {}

variable "identity_type" {
  default = "SystemAssigned"
}

variable "identity_ids" {
  type = list(string)
  default = null
}
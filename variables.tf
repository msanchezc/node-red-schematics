variable "org" {
  description = "Cloud Foundry organization name"
}

variable "space" {
  description = "Cloud Foundry space name"
  default = "dev"
}

variable "app_name" {
  default = "nodered"
}
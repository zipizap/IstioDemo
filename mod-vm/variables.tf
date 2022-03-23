variable "location" {
  type        = string
}

variable "project_name" {
  type        = string
}

variable "hostname" {
  type        = string
}

variable "snets_to_connect" {
  type = map
  description = <<-EOT
    Map of vnet/subnets where a private-ip interface will be dynamically assigned
    Each vnet/subnet must already exist and have 1 free ip for dynamic assignment
 
    Example:
      snets_to_connect = {
        "my_first_subnet" = 
          {
            snet_name = "mysnet0"
            vnet_name = "myvnet0"
            vnet_rg_name = "myvnet0-rg"

            # Dynamic or Static
            private_ip_address_allocation = "Dynamic"
            private_ip_address = "ignored"
          },
        "my_second_subnet" = 
          {
            snet_name = "mysnet1"
            vnet_name = "myvnet1"
            vnet_rg_name = "myvnet1-rg"
            private_ip_address_allocation = "Static"
            private_ip_address = "10.0.1.5"
          },
        ...
        "whatever-alias-here" = 
          {
            snet_name = "mysnetN"
            vnet_name = "myvnetN"
            vnet_rg_name = "myvnetN-rg"
            private_ip_address_allocation = "Static"
            private_ip_address = "10.0.9.6"
          },
      }
  EOT
}

variable "cloudinitfile" {
  type        = string
  description = <<-EOT
     Cloudinit userdata file that is passed into the vm
     If line1 begins with: '#!...' it will be executed as a script.
     If line1 begins with: '#cloud-config' it will be treated as a cloud-config user file (yaml)
  EOT
}

variable "size" {
  type        = string
  description = <<-EOT
    az vm list-skus --location eastus | jq -C '.[].name' | less -R
      "Standard_B1ls"
      "Standard_D2s_v4"
  EOT
  default     = "Standard_B1ls"
}


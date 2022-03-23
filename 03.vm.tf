module "vm" {
  source = "./mod-vm"

  location     = var.location
  project_name = var.project_name
  hostname     = "vm"
  size         = "Standard_D4s_v3"
  snets_to_connect = {
    "snet0" = {
      snet_name = azurerm_subnet.snet0.name
      vnet_name = azurerm_virtual_network.vnet0.name
      vnet_rg_name = azurerm_virtual_network.vnet0.resource_group_name
      private_ip_address_allocation = "Static"
      private_ip_address            = "10.0.0.9"
    },
  }
  cloudinitfile   = "cloudinits/client/cloudinit.userdata.yaml"
  depends_on = [ azurerm_resource_group.rg ]
}

output "pip_vm" {
  value = module.vm.pip
}

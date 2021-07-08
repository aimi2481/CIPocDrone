
provider "azurerm" {
  version  = ">= 2.10.0"
    skip_provider_registration = "true"
  features {}
}
variable "instance_count" {
default = "2"
}

resource "azurerm_resource_group" "rg" {
  name     = "TerraformTesting"
  location = "eastus"
}



resource "azurerm_virtual_network" "vnet" {
  name                = "vNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "10.0.2.0/24"
}


resource "azurerm_network_interface" "example" {
  name                = "nic-${count.index}_r"
   count 	          	= "${var.instance_count}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name


  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_windows_virtual_machine" "example" {
  name                = "exmachine-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  count 	          	= "${var.instance_count}"
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [element(azurerm_network_interface.example.*.id, count.index)]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

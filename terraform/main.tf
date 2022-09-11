terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
    features {}
} 

resource "azurerm_resource_group" "main" {
    name = "Azuredevops"
    location = var.location

    tags = {
        udacityv1 = "${var.rgn}-1"
    }  
}

resource "azurerm_virtual_network" "main" {
    name = "${var.rgn}-network"
    address_space = ["10.0.0.0/22"]
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name 

        tags = {
        udacityv1 = "${var.rgn}-1"
    }  
}

resource "azurerm_network_security_group" "main" {
    name = "${var.rgn}-ng"
    location =azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    security_rule{
        name = "internal-rule"
        priority =100 
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*" 
        destination_port_range     = "*"
        source_address_prefix      = "10.0.0.0/22"
        destination_address_prefix = "10.0.0.0/22"
  }

  security_rule {
    name = "external-rule"
    priority =101 
    direction ="Inbound"
    access= "Deny"
    protocol = "Tcp"
    source_port_range ="*"
    destination_port_range = "*"
    source_address_prefix ="*"
    destination_address_prefix = "*"
  }
    
}



resource "azurerm_subnet" "internal" {
    name = "${var.rgn}-internal-subnet" 
    resource_group_name = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes = ["10.0.0.0/22"]
}



resource "azurerm_network_interface" "main" {
    name = "${var.rgn}-nic"
    resource_group_name = azurerm_resource_group.main.name
    location = azurerm_resource_group.main.location  

    ip_configuration{
        name = "${var.rgn}-internal-primary" 
        subnet_id = azurerm_subnet.internal.id
        private_ip_address_allocation ="Dynamic"
    }

        tags = {
         udacityv1 = "${var.rgn}-1"
    }
}

resource "azurerm_public_ip" "publicIP" {
    name = "${var.rgn}-publi-ip"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name 
    allocation_method = "Dynamic"

    tags = {
         udacityv1 = "${var.rgn}-1"
    }
}



# Load Balancer

resource "azurerm_lb" "main"  {
    name = "${var.rgn}-lb"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    frontend_ip_configuration {
        name = "${var.rgn}-public-address"
        public_ip_address_id = azurerm_public_ip.publicIP.id
    }

        tags = {
         udacityv1 = "${var.rgn}-1"
    }
}

resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.rgn}-backend-address-pool"
}

resource"azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.numbervm
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  ip_configuration_name   = "${var.rgn}-primary"
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
}

resource "azurerm_availability_set" "avset" {
  name                = "${var.rgn}-avset"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    udacityv1 = "${var.rgn}-1"
  }
}


resource "azurerm_linux_virtual_machine" "main" {
    count = var.numbervm 
    name = "${var.rgn}-vm-${count.index}"
    resource_group_name = azurerm_resource_group.main.name
    location = azurerm_resource_group.main.location
    size = "Standard_D2s_v3"
    admin_username = "${var.username}"
    admin_password = "${var.password}" 
    disable_password_authentication = false 
    network_interface_ids = [ 
        azurerm_network_interface.main.id, 
    ]

    source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    udacityv1 = "${var.rgn}-1"
  }
}


resource "azurerm_managed_disk" "data"{
    count = var.numbervm
    name = "${var.rgn}-disk-${count.index}"
    location = azurerm_resource_group.main.location
    create_option = "Empty"
    disk_size_gb = 8
    resource_group_name = azurerm_resource_group.main.name
    storage_account_type = "Standard_LRS" 

    tags = {
    udacityv1 = "${var.rgn}-1"
  }

}


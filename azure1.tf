provider "azurerm"   {

    subscription_id = "90055d39-cc71-4688-af80-3d407bbc3286"
    client_id       = "7b6ddb8a-7e6e-4996-bc40-b2d97f7feaa3"
    client_secret   = "894dd5f6-5d6e-4ea9-97a8-5c90ea523f0a"
    tenant_id       = "9dda556d-221b-436b-a64b-e975cbe2ddd8"

}

#create a resource group if it doesn't exist

resource "azurerm_resource_group" "myterraformgroup"   {

    name = "myResourceGroup"
    location = "eastus"

    tags = {environment = "Terraform Demo"}
}

#create virtual network

resource "azurerm_virtual_network" "myterraformnetwork"   {
    name = "myVnet"
    address_space = ["10.0.0.0/16"]
    location = "eastus"
    resource_group_name = "${azurem_resource_group.myterraformgroup.name}"

    tags = {
        environment = "Terraform Demo"
    }
}

#create subnet

resource "azurerm_subnet" "myterreformsubnet"  {

    name = "mySubnet"
    resource_group_name = "${azurem_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurem_virtual_network.myterraformnetwork.name}"
    address_prefix = "10.0.1.0/24"
}

#create public IPs

resource "azurerm_public_ip" "myterraformpublicip"   {
    name = "myPublicIP"
    location = "eastus"
    resource_group_name = "${azurem_resource_group.myterraformgroup.name}"
    allocation_method = "Dynamic"

    tags={environment = "Terraform Demo"}
}

#create network security group and rule

resource = "azure_network_security_group" "myterraformsg"  {
    name = "myNetworkSecurityGroup"
    location = "eastus"
    resource_group_name = "${azurem_resource_group.myterraformgroup.name}"

    security_rule     {
        name = "SSH"
        priority = 1001
        direction = "Inbound"
        access = "Allow"
        protocal = "Tcp"
        source_port_range = "*"
        destination_port_reange ="22"
        souce_address_prefix = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

#create network interface

resource "azurerm_network_interface" "myterraformnic"   {
    name = "myNIC"
    location ="eastus"
    resource_group_name = "${azurem_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformsg.id}"

    ip_configuration{
        name = "myNicConfiguration"
        subnet_id = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = "${azurerm_public_ip.myterraformpublicip.ip}"

        tags={
            environment = "Terraform Demo"
        }
    }
}

#generate random text fomr a unique storage account name

resource = "random_id" "randomId"    {
    keepers = {
    # generate new id onlu when new resouce is created
    resource_group = "${azurem_resource_group.myterraformgroup.name}"
}
byte_length = 8
}

#create storage account for boot diagnostics

resource "azurerm_storage_account" "mystorageaccout"   {
    name = "diag${random_id.randomId.hex}"
    resource_group_name = "${azurem_resource_group.myterraformgroup.name}"
    location = "eastus"
    account_tier = "Standard"
    account_replication_type = "LRS"

    tags = 
    {
        environment ="Terraform Demo"
    }
}

#create virtual machine

resource "azurerm_virtual_machine" "myterraformvm"{
    name = "myVm"
    location = "eastus"
    resource_group_name  = "${azurem_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size = "Standard_DS1_v2"

    storage_os_disk{
        name = "myOsDisk"
        caching="ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Premium_LRS"

    }

    storage_image_reference{
        publisher="Canonical"
        offer = "UbuntuServer"
        sku = "16.04.0-LTS"
        version = "latest"
    }

    os_profile{
         computer_name = "myvm"
         admin_username ="azureuser"
    }

    os_profile_linux_config{
        disable_password_authentication = true
        ssh_keys{
            path = ""
            key_data = ""
        }
    }

    boot_diagnostics{
        enabled = "true"
        storage_url = "${azurerm_storage_account.mystorageaccoutn.primary_blob_endpoint}"
    }
    tags = {
        environment = "Terraform Demo"
    }

}
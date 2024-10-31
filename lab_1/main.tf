terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.7.0"
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-${var.project_name}-${var.environment}"
  location = var.location

  tags = local.common_tags
}

# Azure SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "${var.prefix}-sql-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"

  tags = local.common_tags
}

# Azure SQL Database
resource "azurerm_mssql_database" "main" {
  name         = "${var.prefix}-db-${var.project_name}-${var.environment}"
  server_id    = azurerm_mssql_server.main.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = var.sql_db_max_size_gb
  sku_name     = var.sql_db_sku

  tags = local.common_tags
}

# Firewall rule to allow Azure services
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Firewall rule to explicitly allow the VM's IP
resource "azurerm_mssql_firewall_rule" "allow_vm_ip" {
  name             = "AllowVMIP"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = azurerm_public_ip.main.ip_address
  end_ip_address   = azurerm_public_ip.main.ip_address
}

# Firewall rule to allow my IP
resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
  name             = "AllowVMIP"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = var.my_ip
  end_ip_address   = var.my_ip
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet-${var.project_name}-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow RDP
  security_rule {
    name                       = "AllowRDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }

  # Allow SQL Server
  # security_rule {
  #   name                       = "AllowSQLServer"
  #   priority                   = 1001
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = var.my_ip
  #   destination_port_range     = "1433"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }

  tags = local.common_tags
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = local.common_tags
}

# Connect NSG to NIC
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  name                  = "${var.prefix}-vm-${var.project_name}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  size                  = "Standard_D2s_v3" # Adjust size as needed
  admin_username        = var.vm_admin_username
  admin_password        = var.vm_admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2019-WS2019"
    sku       = "SQLDEV" # Use "Standard" or "Enterprise" for production
    version   = "latest"
  }

  tags = local.common_tags
}

# Create a storage account
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.common_tags
}

# Create a table within the storage account
resource "azurerm_storage_table" "main" {
  name                 = var.project_name
  storage_account_name = azurerm_storage_account.main.name
}

# Add a table entity
resource "azurerm_storage_table_entity" "example" {
  storage_table_id = azurerm_storage_table.main.id

  partition_key = "examplepartition"
  row_key       = "examplerow"

  entity = {
    example = "example"
  }
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.prefix}-cosmos-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB" # This is for SQL API

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  tags = local.common_tags
}

# Cosmos DB Database
resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "${var.prefix}-cosmosdb-${var.project_name}"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

# Cosmos DB Container
resource "azurerm_cosmosdb_sql_container" "main" {
  name                = "main-container"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths = ["/id"] # Adjust based on your data model

  # 400 RU/s is the minimum and good for development
  throughput = 400

  # Uncomment and adjust if you need indexing policy
  # indexing_policy {
  #   indexing_mode = "consistent"
  #   included_path {
  #     path = "/*"
  #   }
  # }
}
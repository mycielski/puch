# variables.tf
variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "The Azure tenant ID"
  type        = string
}

variable "prefix" {
  description = "The prefix to use for all resources"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (dev, prod, etc.)"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "owner" {
  description = "The owner of the resources (must be a valid email address)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner))
    error_message = "The owner variable must be a valid email address."
  }
}

# SQL Server and Database variables
variable "sql_admin_username" {
  description = "The admin username for the SQL Server"
  type        = string
}

variable "sql_admin_password" {
  description = "The admin password for the SQL Server"
  type        = string
  sensitive   = true
}

variable "sql_db_sku" {
  description = "The SKU for the SQL Database"
  type        = string
}

variable "sql_db_max_size_gb" {
  description = "The maximum size of the SQL Database in GB"
  type        = number
}

# VM variables
variable "vm_admin_username" {
  description = "The admin username for the Windows VM"
  type        = string
}

variable "vm_admin_password" {
  description = "The admin password for the Windows VM"
  type        = string
  sensitive   = true
}

# Storage account variables
variable "storage_account_name" {
  description = "The name of the storage account"
  type        = string
}

variable "storage_account_key" {
  description = "The access key for the storage account"
  type        = string
  sensitive   = true
}

variable "my_ip" {
  description = "Your IP address for firewall rules"
  type        = string
}

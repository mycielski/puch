output "sql_server_name" {
  description = "The name of the SQL Server"
  value       = azurerm_mssql_server.main.name
}

output "sql_server_fqdn" {
  description = "The fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "The name of the SQL Database"
  value       = azurerm_mssql_database.main.name
}

output "sql_admin_username" {
  description = "The admin username for the SQL Server"
  value       = var.sql_admin_username
}

output "sql_admin_password" {
  description = "The admin password for the SQL Server"
  value       = var.sql_admin_password
  sensitive   = true
}

output "vm_admin_username" {
  description = "The admin username for the Windows VM"
  value       = var.vm_admin_username
}

output "vm_admin_password" {
  description = "The admin password for the Windows VM"
  value       = var.vm_admin_password
  sensitive   = true
}

output "vm_public_ip" {
  description = "The public IP address of the Windows VM"
  value       = azurerm_public_ip.main.ip_address
}

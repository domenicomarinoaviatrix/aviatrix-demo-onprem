output "hostname" {
  value = var.hostname
}
output "public_ip" {
  value = var.cloud_type == "aws" ? aws_eip.csr_public_eip[0].public_ip : azurerm_public_ip.csr_public_ip[0].ip_address
}
output "ssh_cmd_csr" {
  value = var.key_name == null ? var.cloud_type == "aws" ? "ssh -i ${var.hostname}-key.pem ec2-user@${aws_eip.csr_public_eip[0].public_ip}" : "ssh -i ${var.hostname}-key.pem adminuser@${azurerm_public_ip.csr_public_ip[0].ip_address}" : null
}
output "ssh_cmd_client" {
  value = var.key_name == null ? var.cloud_type == "aws" ? "ssh -i ${var.hostname}-key.pem ec2-user@${aws_eip.csr_public_eip[0].public_ip} -p 2222" : "ssh -i ${var.hostname}-key.pem adminuser@${azurerm_public_ip.csr_public_ip[0].ip_address} -p 2222" : null
}
output "user_data" {
  value = var.cloud_type == "aws" ? base64decode(data.aws_instance.CSROnprem[0].user_data_base64) : base64decode(azurerm_linux_virtual_machine.CSROnprem[0].custom_data)
}

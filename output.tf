output "hostname" {
  value = var.hostname
}
output "public_ip" {
  value = aws_eip.csr_public_eip[0].public_ip
}
output "ssh_cmd_csr" {
  value = var.key_name == null ? "ssh -i private_key.pem ec2-user@${aws_eip.csr_public_eip[0].public_ip}" : null
}
output "ssh_cmd_client" {
  value = var.key_name == null ? "ssh -i private_key.pem ec2-user@${aws_eip.csr_public_eip[0].public_ip} -p 2222" : null
}
output "user_data" {
  value = base64decode(data.aws_instance.CSROnprem.user_data_base64)
}

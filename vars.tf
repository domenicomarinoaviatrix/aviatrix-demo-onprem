variable "key_name" {
  description = "Existing SSH public key name"
  type        = string
  default     = null
}
variable "vpc_cidr" {
  description = "AWS CSR VPC CIDR block"
}
variable "public_sub" {
  description = "CSR Public subnet"
}
variable "private_sub" {
  description = "CSR Private subnet"
}
variable "instance_type" {
  description = "AWS instance type"
  default     = "t2.medium"
}
variable "aws_deploy_csr" {
  description = "Enable or Disable deployment of CSR in AWS"
  default     = "true"
}
variable "hostname" {
  description = "Hostname of CSR instance"
}
variable "public_conns" {
  type        = list(string)
  description = "List of connections to Aviatrix over Public IPs"
  default     = []
}
variable "private_conns" {
  type        = list(string)
  description = "List of connections to Aviatrix over Private IPs"
  default     = []
}
variable "csr_bgp_as_num" {
  type        = string
  description = "CSR Remote BGP AS Number"
}
variable "create_client" {
  type    = bool
  default = false
}
variable "private_ips" {
  type    = bool
  default = false
}
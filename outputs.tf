output "ec2_eip_dns" {
  value = aws_eip.openvpn.public_dns
}

output "ec2_eip_ip" {
  value = aws_eip.openvpn.public_ip
}

output "connection_string" {
  value = "'ssh -i ${var.ssh_private_key_file} ${var.ec2_username}@${aws_eip.openvpn.public_dns}'"
}


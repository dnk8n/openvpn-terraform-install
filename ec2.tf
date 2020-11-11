data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_key_pair" "openvpn" {
  key_name   = var.ssh_private_key_file
  public_key = file(var.ssh_public_key_file)
}

resource "aws_instance" "openvpn" {
  ami                         = data.aws_ami.amazon_linux_2.id
  associate_public_ip_address = true
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.openvpn.key_name
  subnet_id                   = aws_subnet.openvpn.id

  vpc_security_group_ids = [
    aws_security_group.openvpn.id,
    aws_security_group.ssh_from_local.id,
  ]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.instance_root_block_device_volume_size
    delete_on_termination = true
  }

  tags = {
    Name        = var.tag_name
    Provisioner = "Terraform"
  }
}

resource "null_resource" "openvpn_bootstrap" {
  connection {
    type        = "ssh"
    host        = aws_instance.openvpn.public_ip
    user        = var.ec2_username
    port        = "22"
    private_key = file(var.ssh_private_key_file)
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "curl -O ${var.openvpn_install_script_location}",
      "chmod +x openvpn-install.sh",
      <<EOT
      sudo AUTO_INSTALL=y \
           ENDPOINT=${aws_instance.openvpn.public_dns} \
           ./openvpn-install.sh

EOT
      ,
      "sudo chown -R openvpn:openvpn /etc/openvpn",
    ]
  }
}

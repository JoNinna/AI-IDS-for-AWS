#Upload the public key to AWS
resource "aws_key_pair" "debian_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

#Create and install Suricata on a Linux instance 
resource "aws_instance" "suricata_server" {
  ami           = "ami-0584590e5f0e97daa"  # Debian 12
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.suricata_sg.id]
  key_name      = aws_key_pair.debian_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name
  associate_public_ip_address = true

   user_data = <<-EOF
              #!/bin/bash
              set -eux

              # Dezactivare IPv6
              sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
              sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

              # Actualizare și instalare pachete
              sudo apt-get update -y
              sudo DEBIAN_FRONTEND=noninteractive apt-get install -y suricata awscli cron
              iface=$(ip -o -4 route show to default | awk '{print $5}')
              sudo sudo sed -i "s/interface: .*/interface: $${iface}/" /etc/suricata/suricata.yaml

              # Activare și pornire Suricata
              sudo systemctl enable suricata
              sudo systemctl start suricata

              # Configurare cron job pentru upload loguri
              echo "*/5 * * * * root /usr/bin/aws s3 sync /var/log/suricata s3://${aws_s3_bucket.log_bucket.bucket}/suricata/\$(hostname)/" > /etc/cron.d/suricata-upload
              chmod 0644 /etc/cron.d/suricata-upload
              systemctl restart cron
              EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp2"

  tags = {
    Name = "SuricataServer"
  }
}
}

resource "aws_instance" "falco_server" {
  ami           = "ami-0584590e5f0e97daa"  # Debian 12
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.falco_sg.id]
  key_name      = aws_key_pair.debian_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name
  associate_public_ip_address = true

    user_data = <<-EOF
              #!/bin/bash
              set -e

              # Dezactivează IPv6
              sysctl -w net.ipv6.conf.all.disable_ipv6=1
              sysctl -w net.ipv6.conf.default.disable_ipv6=1
              sysctl -w net.ipv6.conf.lo.disable_ipv6=1
              echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
              echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
              echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
              sysctl -p

              # Actualizează pachetele și instalează dependențele necesare
              sudo apt-get update
              sudo apt-get install -y curl awscli cron
              sudo apt-get install -y gnupg curl lsb-release apt-transport-https ca-certificates

              # Add Falco GPG key
              curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg

              # Add Falco repository
              echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" | tee /etc/apt/sources.list.d/falco.list

              # Install Falco
              apt-get update
              sudo apt-get install -y falco

              # Pornește Falco și configurează-l să pornească automat la boot
              sudo systemctl enable falco
              sudo systemctl start falco

              # Creează cron job pentru upload loguri pe S3
              echo "*/5 * * * * root aws s3 sync /var/log/falco s3://${aws_s3_bucket.log_bucket.bucket}/falco/\$(hostname)/" > /etc/cron.d/falco-upload
              chmod 0644 /etc/cron.d/falco-upload
              systemctl restart cron
              EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "Falco-EC2"
  }
}

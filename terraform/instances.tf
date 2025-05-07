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

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y suricata awscli cron

              sudo systemctl enable suricata
              sudo systemctl start suricata

              echo "*/5 * * * * root aws s3 sync /var/log/suricata s3://${aws_s3_bucket.log_bucket.bucket}/suricata/\$(hostname)/" > /etc/cron.d/suricata-upload
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

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y awscli cron
              curl -s https://s3.amazonaws.com/download.draios.com/stable/install-falco | sudo bash

              sudo systemctl enable falco
              sudo systemctl start falco

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

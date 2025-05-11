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

              # Run the whole script as root
              sudo bash <<'EOF'

              # Dezactivare IPv6
              sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
              sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

              # Actualizare și instalare pachete
              sudo apt-get update -y
              sudo DEBIAN_FRONTEND=noninteractive apt-get install -y suricata awscli cron
              iface=$(ip -o -4 route show to default | awk '{print $5}')
              sudo sed -i "s/interface: .*/interface: $${iface}/" /etc/suricata/suricata.yaml

              # Activare și pornire Suricata
              sudo systemctl enable suricata
              sudo systemctl start suricata

              mkdir -p /var/log/suricata
              chown suricata:suricata /var/log/suricata

              # Modify cron.d permissions for writing
              sudo chmod 0755 /etc/cron.d

              # Configurare cron job pentru upload loguri
              echo "*/5 * * * * root /usr/bin/aws s3 sync /var/log/suricata s3://hids-logs/suricata/$(hostname)/" | sudo tee /etc/cron.d/suricata-upload > /dev/null
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
    set -eux

    # Run the whole script as root
    sudo bash <<'EOF'

    # Disable IPv6
    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1

    # Update and install packages
    apt-get update -y
    apt-get install -y docker.io awscli cron

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    # Create logs directory for Falco
    mkdir -p /opt/falco/logs
    chmod 777 /opt/falco/logs

    # Pull the Falco image if it doesn't exist locally
    docker pull falcosecurity/falco:latest

    # Run the Falco container
    sudo docker run -d --name falco --privileged \
      -v /var/run/docker.sock:/host/var/run/docker.sock \
      -v /dev:/host/dev \
      -v /proc:/host/proc:ro \
      -v /boot:/host/boot:ro \
      -v /lib/modules:/host/lib/modules:ro \
      -v /usr:/host/usr:ro \
      -v /etc:/host/etc:ro \
      -v /opt/falco/logs:/var/log/falco \
      falcosecurity/falco:latest \
      sh -c "falco -o file_output.enabled=true -o file_output.filename=/var/log/falco/falco.log"

    # Create cron job to upload Falco logs to S3 every minute
    cat << 'CRON_EOF' > /etc/cron.d/falco-s3-upload
    * * * * * root /usr/bin/aws s3 cp /opt/falco/logs/falco.log s3://hids-logs/falco-logs/falco-$(date +\%Y\%m\%d\%H\%M).log
    CRON_EOF

    chmod 0644 /etc/cron.d/falco-s3-upload
    crontab /etc/cron.d/falco-s3-upload
    service cron restart
    EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "Falco-EC2"
  }
}

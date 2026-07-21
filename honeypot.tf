# ============================================
# HONEYPOT - Cowrie SSH honeypot
# Isole dans son propre security group
# ============================================

resource "aws_security_group" "honeypot" {
  name        = "${var.project_name}-honeypot-sg"
  description = "Security Group isole pour le honeypot Cowrie"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH factice ouvert a Internet (piege)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Sortie limitee (pas de trafic sortant necessaire)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-honeypot-sg"
  }
}

resource "aws_instance" "honeypot" {
  ami                    = local.fixed_ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.honeypot.id]
  key_name               = aws_key_pair.deployer.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip git
    useradd -m cowrie
    su - cowrie -c "python3 -m venv cowrie-env"
    su - cowrie -c "source cowrie-env/bin/activate && pip install --upgrade pip"
    su - cowrie -c "git clone http://github.com/cowrie/cowrie /home/cowrie/cowrie"
    su - cowrie -c "source cowrie-env/bin/activate && cd /home/cowrie/cowrie && pip install -r requirements.txt"
    cp /home/cowrie/cowrie/etc/cowrie.cfg.dist /home/cowrie/cowrie/etc/cowrie.cfg
    su - cowrie -c "source cowrie-env/bin/activate && cd /home/cowrie/cowrie && bin/cowrie start"
  EOF

  tags = {
    Name = "${var.project_name}-honeypot"
  }
}

output "honeypot_ip" {
  description = "IP publique du honeypot"
  value       = aws_instance.honeypot.public_ip
}

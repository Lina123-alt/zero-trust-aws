output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID du sous-reseau public"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID du sous-reseau prive"
  value       = aws_subnet.private.id
}

output "public_server_ip" {
  description = "IP publique du serveur public"
  value       = aws_instance.public.public_ip
}

output "private_server_ip" {
  description = "IP privee du serveur prive"
  value       = aws_instance.private.private_ip
}

output "ssh_private_key" {
  description = "Cle privee SSH pour se connecter"
  value       = tls_private_key.deployer.private_key_pem
  sensitive   = true
}

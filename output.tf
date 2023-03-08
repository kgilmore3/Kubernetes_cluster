output "kubernetes-Ansible-Server" {
  value = aws_instance.kubernetes-Ansible-Server.public_ip
}
output "Master-Server1" {
  value = aws_instance.Master-Server1.public_ip
}
output "kubernetes-Worker-Server" {
  value = aws_instance.kubernetes-Worker-Server.*.public_ip
}

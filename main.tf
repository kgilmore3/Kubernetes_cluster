# create vpc
resource "aws_vpc" "kubernetes-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "kubernetes-vpc"
  }
}
# create public subnet1
resource "aws_subnet" "kubernetes-pub-sn1" {
  vpc_id            = aws_vpc.kubernetes-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "kubernetes-pub_sn1"
  }
}

# create public subnet2 
resource "aws_subnet" "kubernetes-pub-sn2" {
  vpc_id            = aws_vpc.kubernetes-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "kubernetes-pub-sn2"
  }
}

# create internet gateway
resource "aws_internet_gateway" "kubernetes-igw" {
  vpc_id = aws_vpc.kubernetes-vpc.id
  tags = {
    Name = "kubernetes-igw"
  }
}

# attach the internet gateway to the vpc
resource "aws_vpc_attachment" "kubernetes-attach-igw" {
  vpc_id       = aws_vpc.kubernetes-vpc.id
  internet_gateway_id = aws_internet_gateway.kubernetes-igw.id
}

# 7. route tables
resource "aws_route_table" "kubernetes-rt" {
  vpc_id = aws_vpc.kubernetes-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubernetes-igw.id
  }

  tags = {
    Name = "kubernetes-rt"
  }
}

# 8. route table association for Public Subnet1
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.kubernetes-pub-sn1.id
  route_table_id = aws_route_table.kubernetes-rt.id
}

#  10. route table association for Pubblic Subnet2
resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.kubernetes-pub-sn2.id
  route_table_id = aws_route_table.kubernetes-rt.id
}

# Security Group
resource "aws_security_group" "kubernetes-sg" {
  name        = "kubernetes-sg"
  description = "inbound tls"
  vpc_id      = aws_vpc.kubernetes-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow traffic to NodePort range of kubernetes "
    from_port   = 32757
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "HTTPS"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "kubernetes-sg"
  }
}

# create a keypair
resource "aws_key_pair" "kubernetes-key" {
  key_name   = var.keyname
  public_key = file(var.kubernetes-key)
}

# create master node
resource "aws_instance" "master-node" {
  ami                         = var.ubuntu-ami
  instance_type               = var.instance-type
  vpc_security_group_ids      = [aws_security_group.kubernetes-sg.id]
  subnet_id                   = aws_subnet.kubernetes-pub-sn1.id
  key_name                    = var.keyname
  associate_public_ip_address = true
  tags = {
    Name = "masternode"
  }
}

#Create worker node
resource "aws_instance" "worker-node" {
  count = 2
  ami                         = var.ubuntu-ami
  instance_type               = var.instance-type
  vpc_security_group_ids      = [aws_security_group.kubernetes-sg.id]
  subnet_id                   = aws_subnet.kubernetes-pub-sn2.id
  key_name                    = var.keyname
  associate_public_ip_address = true
  tags = {
    Name = "workernode${count.index}"
  }
}

# Application loadbalancer
resource "aws_lb" "alb" {
  name            = "alb"
  load_balancer_type = "application"
  internal        = false
  security_groups = "kubernetes-sg"
  subnets          = [aws_subnet.kubernetes-pub-sn1.id, aws_subnet.kubernetes-pub-sn2.id]
  enable_deletion_protection = false

  tags = {
    Name = "alb"
  }
}

resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.alb.arn
  protocol          = "HTTP"
  port              = "80"

  default_action {
    target_group_arn = aws_lb_target_group.alb-target-group.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "alb-target-group" {
  name     = "alb-target-group"
  port     = 30001
  protocol = "HTTP"
  vpc_id   = aws_vpc.kubernetes-vpc.id
  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 5
    interval = 30
    timeout = 5
  }
}

resource "aws_lb_target_group_attachment" "alb-target-group-attach" {
  target_group_arn = aws_lb_target_group.alb-target-group.arn
  target_id        = aws_instance.worker-node.*.id
  port = 30001
  count = 3
}


resource "aws_instance" "Ansible-Node" {
  ami                         = var.ami
  instance_type               = var.instance-type
  vpc_security_group_ids      = [aws_security_group.kubernetes-sg.id]
  subnet_id                   = aws_subnet.kubernetes-pub-sn2.id
  key_name                    = var.keyname
  associate_public_ip_address = true
  connection {  
      type        = "ssh" 
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("~/keypairs/kubernetes-key")
    }  
  provisioner "file" {
    source      = "~/keypairs/kubernetes-key"
    destination = "/home/ubuntu/kubernetes-key" 
  }
  provisioner "file" {
      source = "~/Desktop/MyProjects/Kubernetes_cluster/yml"
      destination = "/home/ubuntu/yml"    
  }
  provisioner "remote-exec" {
      inline = [
        "sudo apt-get update -y",
        "sudo apt-get install software-properties-common -y",
        "sudo add-apt-repository --yes --update ppa:ansible/ansible", 
        "sudo apt-get install ansible -y", 
        "sudo chmod 400 /home/ubuntu/kubernetes-key",
        "sudo mkdir /etc/ansible", 
        "sudo touch /etc/ansible/hosts",
        "sudo chown ubuntu:ubuntu /etc/ansible/hosts",
        "sudo bash -c ' echo \"StrictHostKeyChecking No\" >> /etc/ssh/ssh_config'",
        "sudo echo \"[Master]\" >> /etc/ansible/hosts",
        "sudo echo \"${aws_instance.master-node.public_ip} ansible_ssh_private_key_file=/home/ubuntu/kubernetes-key\" >> /etc/ansible/hosts",
        "sudo echo \"[Workers]\" >> /etc/ansible/hosts",
        "sudo echo \"${aws_instance.worker-node[0].public_ip} ansible_ssh_private_key_file=/home/ubuntu/kubernetes-key\" >> /etc/ansible/hosts",
        "sudo echo \"${aws_instance.worker-node[1].public_ip} ansible_ssh_private_key_file=/home/ubuntu/kubernetes-key\" >> /etc/ansible/hosts",
        "ansible -m ping all",
        "ansible-playbook -i /etc/ansible/hosts yml/installation.yml",
        "ansible-playbook -i /etc/ansible/hosts yml/cluster.yml",
        "ansible-playbook -i /etc/ansible/hosts yml/join_master.yml",
           
      ]
  }  
  tags = {
    Name = "Ansible-Node"
  }
  
}# Create Jenkins Server
resource "aws_instance" "jenkins_server" {
  ami                         = var.redhat-ami
  instance_type               = var.instance-type
  vpc_security_group_ids      = [aws_security_group.kubernetes-sg.id]
  subnet_id                   = aws_subnet.kubernetes-pub-sn2.id
  key_name                    = var.keyname
  user_data                   = <<-EOF
#!/bin/bash
sudo yum update -y
sudo yum install wget -y
sudo yum install git -y
sudo yum install maven -y
sudo wget https://get.jenkins.io/redhat/jenkins-2.346-1.1.noarch.rpm
sudo rpm -ivh jenkins-2.346-1.1.noarch.rpm
sudo yum install java-11-openjdk -y
sudo systemctl daemon-reload
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins
sudo hostnamectl set-hostname Jenkins
EOF
  tags = {
    Name = "Jenkins"
  }
} 
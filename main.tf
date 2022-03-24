provider "aws" {
  region = "eu-west-1"
}

# Security Group
variable "ingressrules" {
  type    = list(number)
  default = [8080, 22]
}
resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "inbound ports for ssh and standard http and everything outbound"
  vpc_id      = "vpc-00419ce6f87be0559"
  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Terraform" = "true"
  }
}

data "aws_ami" "amazon_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  # owners = ["*"]
  owners = ["137112412989"]
}

resource "aws_instance" "jenkins" {
  ami             = data.aws_ami.amazon_ami.id
  # ami             = "ami-0069d66985b09d219"
  instance_type   = "t3.medium"
  security_groups = [aws_security_group.web_traffic.id]
  key_name        = "nikhil-aws-pe-dev"
  subnet_id       = "subnet-0768f19278aacbe9d"
  # user_data = "${file("userdata.sh")}"

    provisioner "remote-exec" {
    inline = [
      "sudo yum update –y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum upgrade",
      "sudo amazon-linux-extras install java-openjdk11 -y",
      "sudo useradd jenkins",
      "echo \"nikhil\" | sudo passwd jenkins --stdin",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl status jenkins",
      "sudo yum install docker",
      "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("nikhil-aws-pe-dev.pem")
  }

  tags = {
    "Name" = "Jenkins"
    "Owner" = "Nikhil"
  }
}
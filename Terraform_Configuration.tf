provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "ERCLI_CP1_Ubuntu" {
  count         = 1
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  key_name      = "ERCLI_CEP1_Key"
  vpc_security_group_ids = [aws_security_group.ERCLI_CP1_Security_Group.id]
  tags = {
    Name = "ERCLI_CP1_Ubuntu${count.index + 1}"
  }
}
resource "aws_security_group" "ERCLI_CP1_Security_Group" {
  name_prefix = "ERCLI_CP1_SecGroup"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all incoming traffic from any IPv4 address"
  }
  egress {
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outgoing apt update traffic (HTTP and HTTPS) to any IPv4 address"
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outgoing apt install traffic (SSH) to any IPv4 address"
  }
}
resource "null_resource" "Installation_via_Ansible" {
  count = length(aws_instance.ERCLI_CP1_Ubuntu)

  provisioner "local-exec" {
    command = <<-EOT
      max_retries=5
      retries=0
      while [ $retries -lt $max_retries ]; do
        ssh -i /home/elmerlakanilawy/CapstoneProject/ERCLI-CEP1/ERCLI_CEP1_Key.pem -o ConnectTimeout=20 root@${aws_instance.ERCLI_CP1_Ubuntu[count.index].public_ip} exit && break
        retries=$((retries+1))
        sleep 10
      done
      ansible-playbook -i '${aws_instance.ERCLI_CP1_Ubuntu.*.public_ip[count.index]},' Ansible_Playbook.yaml --private-key=/home/elmerlakanilawy/CapstoneProject/ERCLI-CEP1/ERCLI_CEP1_Key.pem
    EOT
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
}

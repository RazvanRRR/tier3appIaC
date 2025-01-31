#!/bin/bash
sleep 60s
sudo yum install -y httpd
systemctl enable httpd
systemctl start httpd

# Echo a dynamic message
names=$(hostname)
sudo echo "Hello from $names instance" > /var/www/html/index.html

# Enable password-based SSH (AGAIN: not secure for production)
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Set a password for ec2-user
echo "ec2-user:MySuperSecretPassword1!" | chpasswd

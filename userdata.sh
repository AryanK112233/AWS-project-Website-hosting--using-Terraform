#!/bin/bash
sudo apt update
sudo apt install -y apache2


INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)


sudo cat <<EOF | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>My Portfolio</title>
  <style>
    /* Add animation and styling for the text */
    @keyframes colorChange {
      0% { color: red; }
      50% { color: green; }
      100% { color: blue; }
    }
    h1 {
      animation: colorChange 2s infinite;
    }
  </style>
</head>
<body>
  <h1>Terraform Project Server 1</h1>
  <h2>Instance ID: <span style="color:green">$INSTANCE_ID</span></h2>
  <p>Welcome user</p>
</body>
</html>
EOF


sudo systemctl start apache2
sudo systemctl enable apache2
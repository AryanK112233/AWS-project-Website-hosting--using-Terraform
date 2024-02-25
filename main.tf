resource "aws_vpc" "myvpc" {
  
  cidr_block = var.cidr
}
resource "aws_subnet" "sub1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
  
}
resource "aws_subnet" "sub2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true
  
}
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.myvpc.id
}
resource "aws_route_table" "RT" {
    vpc_id = aws_vpc.myvpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}
resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.RT.id
  
}
resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.sub2.id
    route_table_id = aws_route_table.RT.id
  
}

resource "aws_security_group" "websg" {
  name        = "web"
  vpc_id      = aws_vpc.myvpc.id

  tags = {
    Name = "web"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv41" {
  security_group_id = aws_security_group.websg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv42" {
  security_group_id = aws_security_group.websg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.websg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports

}

resource "aws_instance" "webserver1" {
  ami = "ami-0a7cf821b91bcccbc"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id = aws_subnet.sub1.id
  user_data = base64encode(file("userdata.sh"))
}

resource "aws_instance" "webserver2" {
  ami = "ami-0a7cf821b91bcccbc"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id = aws_subnet.sub2.id
  user_data = base64encode(file("userdata1.sh"))
}


resource "aws_lb" "myalb" {
  name = "myalb"
  internal = false
  load_balancer_type = "application"
  security_groups = [ aws_security_group.websg.id ]
  subnets = [ aws_subnet.sub1.id,aws_subnet.sub2.id ]
  
}
resource "aws_lb_target_group" "mytg" {
  name = "mytg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.myvpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id = aws_instance.webserver1.id
  port = 80
  
}
resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id = aws_instance.webserver2.id
  port = 80
  
}
resource "aws_lb_listener" "name" {
  load_balancer_arn = aws_lb.myalb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.mytg.arn
    type = "forward"
  }

}
output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
  
}

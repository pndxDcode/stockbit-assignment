#provider "aws" {
  #access_key = “aws_access_key_id”
  #secret_key = “aws_secret_access_key_id”
  #region     = "ap-south-1"
#}
#data "aws_availability_zones" "all" {
    #names = ["ap-southeast-1a"]
    ##"ap-southeast-1b"
    ##"ap-southeast-1c"
#}
### Creating EC2 instance
resource "aws_instance" "web" {
  subnet_id         = "${aws_subnet.private.id}"
  ami               = "${lookup(var.amis,var.region)}"
  count             = "${var.counting}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  source_dest_check = false
  instance_type = "t2.medium"

  #tags {
    #Name = "${format("web-%03d", count.index + 1)}"
  #}
}
### Creating Security Group for EC2
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
## Creating Launch Configuration
resource "aws_launch_configuration" "stockbit" {
  image_id               = "${lookup(var.amis,var.region)}"
  instance_type          = "t2.micro"
  security_groups        = ["${aws_security_group.instance.id}"]
  key_name               = "${var.key_name}"
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}
## Creating AutoScaling Group
resource "aws_autoscaling_group" "stockbit" {
  launch_configuration = "${aws_launch_configuration.stockbit.id}"
  #availability_zones = ["${data.aws_availability_zones.all.names}"]
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
  min_size = 2
  max_size = 5
  load_balancers = ["${aws_elb.stockbit.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "terraform-asg-stockbit"
    propagate_at_launch = true
  }
}
## Security Group for ELB
resource "aws_security_group" "elb" {
  name = "terraform-stockbit-elb"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
### Creating ELB
resource "aws_elb" "stockbit" {
  name = "terraform-asg-stockbit"
  security_groups = ["${aws_security_group.elb.id}"]
  #availability_zones = ["${data.aws_availability_zones.all.names}"]
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:8080/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "8080"
    instance_protocol = "http"
  }
}

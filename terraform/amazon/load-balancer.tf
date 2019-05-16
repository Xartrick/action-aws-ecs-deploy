resource "aws_alb" "main" {
  load_balancer_type = "application"
  name = "${var.logical_name}-lb"
  subnets = [
    "${data.aws_subnet.default.*.id}"]
  security_groups = [
    "${aws_security_group.lb.id}"]
}

resource "aws_alb_target_group" "app" {
  name = "${substr(var.logical_name, 0, min(length(var.logical_name), 32))}"
  port = "${var.port}"
  protocol = "HTTP"
  vpc_id = "${data.aws_vpc.default.id}"
  target_type = "ip"
  health_check {
    path = "${var.health_check_endpoint}"
    port = "${var.port}"
  }
}

resource "aws_alb_listener" "https" {
  count = "${var.is_worker ? 0 : 1}" # no cname if worker
  load_balancer_arn = "${aws_alb.main.id}"
  port = "443"
  protocol = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn = "${data.aws_acm_certificate.main.arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.app.id}"
    type = "forward"
  }
}
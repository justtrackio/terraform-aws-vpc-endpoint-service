locals {
  data_subnets = try(data.aws_subnets.subnets[0].ids, [])
  subnet_ids   = coalescelist(tolist(local.data_subnets), var.lb_subnet_ids)
}

resource "aws_lb" "lb" {
  name                             = "${module.this.id}-vpces"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = local.subnet_ids
  enable_deletion_protection       = var.lb_enable_deletion_protection
  enable_cross_zone_load_balancing = var.lb_enable_cross_zone_load_balancing

  tags = module.this.tags
}

resource "aws_lb_target_group" "target_group" {
  name     = "${module.this.environment}-${module.this.stage}-${module.this.name}"
  port     = var.lb_target_group_port
  protocol = "TCP"
  vpc_id   = var.vpc_id

  tags = module.this.tags
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  tags = module.this.tags
}

resource "aws_vpc_endpoint_service" "service" {
  acceptance_required        = var.endpoint_service_acceptance_required
  network_load_balancer_arns = [aws_lb.lb.arn]
  allowed_principals         = var.endpoint_service_allowed_principals

  tags = module.this.tags
}

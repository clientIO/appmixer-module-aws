locals {
  route53_enabled         = var.zone_id != null
  acm_certificate_enabled = var.certificate_arn == null && local.route53_enabled
  acm_certificate_arn     = local.acm_certificate_enabled ? aws_acm_certificate.alb[0].arn : var.certificate_arn
}

resource "aws_route53_record" "alb" {
  count   = local.route53_enabled ? 1 : 0
  zone_id = var.zone_id
  name    = "*.${var.root_dns_name}"
  type    = "CNAME"
  ttl     = 300
  records = [try(module.alb.dns_name, "")]
}

resource "aws_acm_certificate" "alb" {
  count             = local.acm_certificate_enabled ? 1 : 0
  domain_name       = "*.${var.root_dns_name}"
  validation_method = "DNS"

  tags = module.label.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_alb" {
  for_each = {
    for dvo in try(aws_acm_certificate.alb[0].domain_validation_options, []) : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    } if local.acm_certificate_enabled
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}


resource "aws_acm_certificate_validation" "this" {
  count                   = local.acm_certificate_enabled ? 1 : 0
  certificate_arn         = aws_acm_certificate.alb[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_alb : record.fqdn]
}

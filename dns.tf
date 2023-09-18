resource "aws_route53_record" "east-kafka-0" {
  provider = aws.aws-east
  allow_overwrite = true
  name            = "kafka.east.broker0.mydomain.com"
  type            = "A"
  zone_id         = aws_route53_zone.default.zone_id
  alias {
    name                   = data.aws_lb.east-kakfa-0.dns_name
    zone_id                = data.aws_lb.east-kakfa-0.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "east-kafka-1" {
  provider = aws.aws-east
  allow_overwrite = true
  name            = "kafka.east.broker1.mydomain.com"
  type            = "A"
  zone_id         = aws_route53_zone.default.zone_id
  alias {
    name                   = data.aws_lb.east-kakfa-1.dns_name
    zone_id                = data.aws_lb.east-kakfa-1.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "east-kafka-lb" {
  provider = aws.aws-east
  allow_overwrite = true
  name            = "kafka.east.mydomain.com"
  type            = "A"
  zone_id         = aws_route53_zone.default.zone_id
  alias {
    name                   = data.aws_lb.east-kakfa-lb.dns_name
    zone_id                = data.aws_lb.east-kakfa-lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "central-kafka-0" {
  provider = aws.aws-central
  allow_overwrite = true
  name            = "kafka.central.broker0.mydomain.com"
  type            = "A"
  zone_id         = aws_route53_zone.default.zone_id
  alias {
    name                   = data.aws_lb.central-kakfa-0.dns_name
    zone_id                = data.aws_lb.central-kakfa-0.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "central-kafka-1" {
  provider = aws.aws-central
  allow_overwrite = true
  name            = "kafka.central.broker1.mydomain.com"
  type            = "A"
  zone_id         = aws_route53_zone.default.zone_id
  alias {
    name                   = data.aws_lb.central-kakfa-1.dns_name
    zone_id                = data.aws_lb.central-kakfa-1.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "central-kafka-lb" {
  provider = aws.aws-central
  allow_overwrite = true
  name            = "kafka.central.mydomain.com"
  type            = "A"
  zone_id         = aws_route53_zone.default.zone_id
  alias {
    name                   = data.aws_lb.central-kakfa-lb.dns_name
    zone_id                = data.aws_lb.central-kakfa-lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "central-controlcenter-lb" {
  provider = aws.aws-central
  allow_overwrite = true
  name            = "confluent.controlcenter.mydomain.com"
  type            = "A"
  zone_id         = aws_route53_zone.default.zone_id
  alias {
    name                   = data.aws_lb.central-controlcenter-lb.dns_name
    zone_id                = data.aws_lb.central-controlcenter-lb.zone_id
    evaluate_target_health = true
  }
}


resource "aws_route53_record" "west-kafka-0" {
  provider = aws.aws-west
  allow_overwrite = true
  name            = "kafka.west.broker0.mydomain.com"
  type            = "A"
  zone_id         = aws_route53_zone.default.zone_id
  alias {
    name                   = data.aws_lb.west-kakfa-0.dns_name
    zone_id                = data.aws_lb.west-kakfa-0.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "west-kafka-1" {
  provider = aws.aws-west
  allow_overwrite = true
  name            = "kafka.west.broker1.mydomain.com"
  type            = "A"
  zone_id         = aws_route53_zone.default.zone_id
  alias {
    name                   = data.aws_lb.west-kakfa-1.dns_name
    zone_id                = data.aws_lb.west-kakfa-1.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "west-kafka-lb" {
  provider = aws.aws-west
  allow_overwrite = true
  name            = "kafka.west.mydomain.com"
  type            = "A"
  zone_id         = aws_route53_zone.default.zone_id
  alias {
    name                   = data.aws_lb.west-kakfa-lb.dns_name
    zone_id                = data.aws_lb.west-kakfa-lb.zone_id
    evaluate_target_health = true
  }
}
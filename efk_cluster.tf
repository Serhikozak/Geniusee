resource "aws_security_group" "es" {
  name = "For_es"
  description = "Allow inbound traffic to ElasticSearch from VPC CIDR"
  vpc_id = aws_vpc.Geniusee_EKS.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      aws_vpc.Geniusee_EKS.cidr_block
    ]
  }
}

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

data "aws_caller_identity" "current" {}

resource "aws_elasticsearch_domain" "es" {
  domain_name = var.domain
  elasticsearch_version = "7.10"

  cluster_config {
    instance_count = 2
    instance_type = "m5.large.elasticsearch"
    zone_awareness_enabled = true

    zone_awareness_config {
      availability_zone_count = 2
    }
  }

  vpc_options {
    subnet_ids = [for s in aws_subnet.public : s.id]
    security_group_ids = [aws_security_group.es.id]

  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "es:*",
          "Principal": "*",
          "Effect": "Allow",
          "Resource": "arn:aws:es:var.aws_region:data.aws_caller_identity.current.account_id:domain/es_for_eks/*"
      }
  ]
}
  CONFIG

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = {
    Domain = "es_for_eks"
  }
}

output "elk_endpoint" {
  value = aws_elasticsearch_domain.es.endpoint
}

output "elk_kibana_endpoint" {
  value = aws_elasticsearch_domain.es.kibana_endpoint
}
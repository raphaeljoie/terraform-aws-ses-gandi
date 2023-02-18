data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "gandi_livedns_domain" "domain" {
  name = var.domain
}

locals {
  aws_region = var.aws_region == null ? data.aws_region.current.name : var.aws_region
}

resource "aws_ses_domain_identity" "domain_identity" {
  domain = var.domain
}

######## VERIFICATION ########
resource "gandi_livedns_record" "verification_record" {
  zone = data.gandi_livedns_domain.domain.id
  name = "_amazonses.${aws_ses_domain_identity.domain_identity.id}"
  type = "TXT"
  ttl = var.ttl
  values = [aws_ses_domain_identity.domain_identity.verification_token]
}

resource "aws_ses_domain_identity_verification" "verification" {
  count = var.verification ? 1 : 0
  domain = aws_ses_domain_identity.domain_identity.id

  depends_on = [gandi_livedns_record.verification_record]
}

######## DKIM ########
resource "aws_ses_domain_dkim" "dkim" {
  domain = aws_ses_domain_identity.domain_identity.domain
}

resource "gandi_livedns_record" "dkim_record" {
  count   = 3
  zone = data.gandi_livedns_domain.domain.id
  name = "${aws_ses_domain_dkim.dkim.dkim_tokens[count.index]}._domainkey"
  type = "CNAME"
  ttl = var.ttl
  values = [
    "${aws_ses_domain_dkim.dkim.dkim_tokens[count.index]}.dkim.amazonses.com."
  ]
}

######### MAIL FROM ########
resource "aws_ses_domain_mail_from" "mail_from" {
  count = var.mail_from_subdomain == null ? 0 : 1
  domain           = aws_ses_domain_identity.domain_identity.domain
  mail_from_domain = "${var.mail_from_subdomain}.${aws_ses_domain_identity.domain_identity.domain}"
  behavior_on_mx_failure = var.behavior_on_mx_failure
}

resource "gandi_livedns_record" "mail_from_mx_record" {
  count = var.mail_from_subdomain == null ? 0 : 1
  zone = data.gandi_livedns_domain.domain.id
  name = replace(aws_ses_domain_mail_from.mail_from[0].mail_from_domain, ".${data.gandi_livedns_domain.domain.name}", "")
  type = "MX"
  ttl = var.ttl
  values = ["10 feedback-smtp.${local.aws_region}.amazonses.com."]
}

resource "gandi_livedns_record" "mail_from_txt_record" {
  count = var.mail_from_subdomain == null ? 0 : 1
  zone = data.gandi_livedns_domain.domain.id
  name = replace(aws_ses_domain_mail_from.mail_from[0].mail_from_domain, ".${data.gandi_livedns_domain.domain.name}", "")
  type = "TXT"
  ttl = var.ttl
  values = ["v=spf1 include:amazonses.com -all"]
}

######## RECEPTION ########
resource "gandi_livedns_record" "redirection_mx_record" {
  count = var.reception_subdomain != null ? 1 : 0
  zone = data.gandi_livedns_domain.domain.id
  name = var.reception_subdomain
  type = "MX"
  ttl = var.ttl
  values = ["10 inbound-smtp.${local.aws_region}.amazonaws.com."]
}

## Bucket
resource "aws_s3_bucket" "reception_bucket" {
  count = var.reception_subdomain != null && var.reception_bucket != null ? 1 : 0
  bucket = var.reception_bucket
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  count = var.reception_subdomain != null && var.reception_bucket != null ? 1 : 0
  bucket = aws_s3_bucket.reception_bucket[0].bucket
  policy = jsonencode({
    Statement = [
      {
        Action = "s3:PutObject"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          StringLike = {
            "AWS:SourceArn" = "arn:aws:ses:*"
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Resource = "arn:aws:s3:::${aws_s3_bucket.reception_bucket[0].bucket}/*"
        Sid = "AllowSESPuts-1676672006274"
      },
    ]
    Version = "2012-10-17"
  })
}

##
resource "aws_sns_topic" "reception_sns" {
  count = var.reception_subdomain != null && var.reception_sns != null ? 1 : 0
  name = var.reception_sns
}

resource "aws_sns_topic_policy" "reception_sns_policy" {
  count = var.reception_subdomain != null && var.reception_sns != null ? 1 : 0

  arn = aws_sns_topic.reception_sns[0].arn
  policy = jsonencode({
    Statement = [
      {
        Action = "SNS:Publish"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.id
          }
          StringLike = {
            "AWS:SourceArn" = "arn:aws:ses:*"
          }
        }
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Resource = aws_sns_topic.reception_sns[0].arn
        Sid = "stmt1676733667555"
      },
    ]
    Version = "2008-10-17"
  })
}

resource "aws_ses_receipt_rule_set" "this" {
  count = var.reception_subdomain != null && var.reception_bucket != null ? 1 : 0

  rule_set_name = "default"
}

resource "aws_ses_active_receipt_rule_set" "main" {
  count = var.reception_subdomain != null && var.reception_bucket != null ? 1 : 0

  rule_set_name = aws_ses_receipt_rule_set.this[0].rule_set_name
}

resource "aws_ses_receipt_rule" "this" {
  count = var.reception_subdomain != null && var.reception_bucket != null ? 1 : 0

  name          = "${var.reception_subdomain}.${var.domain}"
  rule_set_name = aws_ses_receipt_rule_set.this[0].rule_set_name
  recipients    = ["${var.reception_subdomain}.${var.domain}"]
  enabled       = true
  scan_enabled  = true

  add_header_action {
    header_name  = "Custom-Header"
    header_value = "Added by SES"
    position     = 1
  }

  dynamic "s3_action" {
    for_each = toset(var.reception_bucket == null ? [] : [var.reception_bucket])
    content {
      bucket_name = s3_action.key
      position    = 2
    }
  }

  dynamic "sns_action" {
    for_each = toset(var.reception_sns == null ? [] : [var.reception_sns])
    content {
      encoding  = var.reception_sns_encoding
      position  = 3
      topic_arn = aws_sns_topic.reception_sns[0].arn
    }
  }
}

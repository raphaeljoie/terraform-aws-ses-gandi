# Terraform module for Gandi configuration of AWS SES for sending and receiving secure emails

Configure Gandi and AWS SES to collect mails sent to a given subdomain,
and store them in a S3 bucket.

This module also configures AWS SES as a service to send secure emails using
the given domain name.

```terraform
module "gandi_ses" {
  source  = "git::https://github.com/raphaeljoie/terraform-aws-ses-gandi.git"
  
  domain = "beccountant.be"
  reception_bucket = "beccountantmails"
  reception_subdomain = "bot"
  mail_from_subdomain = "mail"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |
| <a name="requirement_gandi"></a> [gandi](#requirement\_gandi) | ~> 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |
| <a name="provider_gandi"></a> [gandi](#provider\_gandi) | ~> 2.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.reception_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_ses_active_receipt_rule_set.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_active_receipt_rule_set) | resource |
| [aws_ses_domain_dkim.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_dkim) | resource |
| [aws_ses_domain_identity.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity) | resource |
| [aws_ses_domain_identity_verification.example_verification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity_verification) | resource |
| [aws_ses_domain_mail_from.mail_from](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_mail_from) | resource |
| [aws_ses_receipt_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule) | resource |
| [aws_ses_receipt_rule_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule_set) | resource |
| [gandi_livedns_record.dkim_record](https://registry.terraform.io/providers/go-gandi/gandi/latest/docs/resources/livedns_record) | resource |
| [gandi_livedns_record.mail_from_mx_record](https://registry.terraform.io/providers/go-gandi/gandi/latest/docs/resources/livedns_record) | resource |
| [gandi_livedns_record.mail_from_txt_record](https://registry.terraform.io/providers/go-gandi/gandi/latest/docs/resources/livedns_record) | resource |
| [gandi_livedns_record.redirection_mx_record](https://registry.terraform.io/providers/go-gandi/gandi/latest/docs/resources/livedns_record) | resource |
| [gandi_livedns_record.verification_record](https://registry.terraform.io/providers/go-gandi/gandi/latest/docs/resources/livedns_record) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [gandi_livedns_domain.example_com](https://registry.terraform.io/providers/go-gandi/gandi/latest/docs/data-sources/livedns_domain) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS SES region | `string` | `null` | no |
| <a name="input_behavior_on_mx_failure"></a> [behavior\_on\_mx\_failure](#input\_behavior\_on\_mx\_failure) | When Mail From is enabled, behaviour when MX failed. 'RejectMessage' or 'UseDefaultValue' accepted | `string` | `"RejectMessage"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name for which the AWS SES mail service must be configured. The Gandi LiveDNS must already exist for that domain | `string` | n/a | yes |
| <a name="input_mail_from_subdomain"></a> [mail\_from\_subdomain](#input\_mail\_from\_subdomain) | Subdomain used by AWS SES when sending email. Use null for skipping the Mail From configuration. Otherwise {mail\_from\_subdomain}.{var.domain} will be used | `string` | `null` | no |
| <a name="input_reception_bucket"></a> [reception\_bucket](#input\_reception\_bucket) | S3 bucket to keep the message received. Use null value for skipping S3 Bucket storage action | `string` | `null` | no |
| <a name="input_reception_subdomain"></a> [reception\_subdomain](#input\_reception\_subdomain) | subdomain | `string` | `"bot"` | no |
| <a name="input_ttl"></a> [ttl](#input\_ttl) | TTL for DNS records at Gandi. Min is 300 | `number` | `600` | no |
| <a name="input_verification"></a> [verification](#input\_verification) | Run the identity verification phase, or not. WARNING: Can last a while (45 minutes timeout) | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Dev
```sh
terraform-docs markdown table ./ --output-file README.md
```

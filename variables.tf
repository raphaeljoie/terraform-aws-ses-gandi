variable "domain" {
  type        = string
  description = "Domain name for which the AWS SES mail service must be configured. The Gandi LiveDNS must already exist for that domain"
}

variable "mail_from_subdomain" {
  type        = string
  default     = null
  description = "Subdomain used by AWS SES when sending email. Use null for skipping the Mail From configuration. Otherwise {mail_from_subdomain}.{var.domain} will be used"
}

variable "verification" {
  type        = bool
  default     = false
  description = "Run the identity verification phase, or not. WARNING: Can last a while (45 minutes timeout)"
}

variable "aws_region" {
  type        = string
  default     = null
  description = "AWS SES region"
}

variable "behavior_on_mx_failure" {
  type        = string
  default     = "RejectMessage"
  description = "When Mail From is enabled, behaviour when MX failed. 'RejectMessage' or 'UseDefaultValue' accepted"
}

variable "ttl" {
  type        = number
  default     = 600
  description = "TTL for DNS records at Gandi. Min is 300"
}

variable "reception_subdomain" {
  type        = string
  default     = "bot"
  description = "Redirect emails from the subdomain (@{reception_subdomain}.{domain}) to SES, and redirect to bucket if configured"
}

variable "reception_bucket" {
  type        = string
  default     = null
  description = "S3 bucket to keep the message received. Use null value for skipping S3 Bucket storage action"
}

variable "reception_sns" {
  type        = string
  default     = null
  description = "SNS "
}

variable "reception_sns_encoding" {
  type = string
  default = "Base64"
  description = ""
}
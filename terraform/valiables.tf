variable "app_name" {
  type        = string
  default     = "simutrans-makeobj"
  description = "アプリ名"
}
variable "log_retention_in_days" {
  type        = number
  default     = 7
  description = "ログ保持期間"
}

variable "log_format" {
  type    = string
  default = "$context.requestId $context.identity.sourceIp $context.identity.userAgent $context.requestTime"
  # エラー調査用
  # default     = "$context.requestId $context.identity.sourceIp $context.identity.userAgent $context.requestTime $context.integrationErrorMessage $context.authorizer.error"
  description = "APIアクセスログのフォーマット"
}

variable "api_path" {
  type        = string
  default     = "/makeobj-list"
  description = "APIエンドポイントのパス"
}

resource "aws_lambda_function" "func" {

  function_name = local.naming_prefix
  role          = aws_iam_role.lambda.arn

  handler = "main.handler"
  runtime = "python3.8"

  filename         = data.archive_file.func.output_path
  source_code_hash = filebase64sha256(data.archive_file.func.output_path)

  timeout     = var.event_processing_timeout
  memory_size = 128

  layers = [local.python_layers[var.region]]

  environment {
    variables = {
      WEBHOOK_PARAMETER     = aws_ssm_parameter.slack_webhook.name
      DATADOG_API_PARAMETER = aws_ssm_parameter.datadog_api.name
      DATADOG_APP_PARAMETER = aws_ssm_parameter.datadog_app.name
      EXCLUDED_ACCOUNTS     = jsonencode(var.excluded_accounts)
      INCLUDED_ACCOUNTS     = jsonencode(var.included_accounts)
    }
  }
}

data "archive_file" "func" {
  type             = "zip"
  source_dir       = "${path.module}/lambda"
  output_file_mode = "0666"
  output_path      = "${path.module}/lambda.zip"
}

resource "aws_lambda_event_source_mapping" "bucket_notifications" {
  event_source_arn = aws_sqs_queue.bucket_notifications.arn
  function_name    = aws_lambda_function.func.arn
}

resource "aws_ssm_parameter" "slack_webhook" {

  name        = "/${local.naming_prefix}/slack-webhook"
  description = "Slack Incomming Webhook. https://api.slack.com/messaging/webhooks"

  type  = "SecureString"
  value = "REPLACE_ME"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "datadog_api" {

  name        = "/${local.naming_prefix}/datadog_api"
  description = "Datadog api key for pushing metrics. https://docs.datadoghq.com/account_management/api-app-keys/"

  type  = "SecureString"
  value = "REPLACE_ME"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "datadog_app" {

  name        = "/${local.naming_prefix}/datadog_app"
  description = "Datadog app key for pushing metrics. https://docs.datadoghq.com/account_management/api-app-keys/"

  type  = "SecureString"
  value = "REPLACE_ME"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

# Define the AWS region
variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-3"  # Modify to your region if needed
}

# Define the path for the Lambda function zip file
variable "lambda_function_zip" {
  description = "Path to the Lambda function zip file"
  default     = "./lambda/function.zip"  # Path to the zip file
}

# Define the DynamoDB table name
variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  default     = "resume-challenge-test"
}

# Define the CloudFront distribution ID (optional, for cache invalidation)
variable "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  default     = "E2FQP8EGNCNWNE"  
}

# DynamoDB Table
resource "aws_dynamodb_table" "visitor_count" {
  name           = var.dynamodb_table_name
  hash_key       = "id"
  read_capacity  = 5
  write_capacity = 5
  table_class    = "STANDARD"

  attribute {
    name = "id"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true  # This prevents accidental deletion of the table
    ignore_changes   = [name, read_capacity, write_capacity]  # Prevents changes to the table schema
  }
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for DynamoDB Access
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda_dynamodb_policy"
  description = "Lambda policy to interact with DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.visitor_count.arn
      }
    ]
  })
}

# Attach IAM policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}

# Lambda Function
resource "aws_lambda_function" "visitor_count_function" {
  filename      = var.lambda_function_zip  # Path to the zip file
  function_name = "VisitorCountFunction"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "app.lambda_handler"  # Lambda entry point
  runtime       = "python3.8"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_count.name
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "visitor_api" {
  name        = "VisitorCountApi"
  description = "API for visitor count"
}

# Root resource for the API Gateway
resource "aws_api_gateway_resource" "visitor_resource" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  parent_id   = aws_api_gateway_rest_api.visitor_api.root_resource_id
  path_part   = "visitor"
}

# GET Method for the API Gateway
resource "aws_api_gateway_method" "visitor_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_api.id
  resource_id   = aws_api_gateway_resource.visitor_resource.id
  http_method   = "GET"  # This defines the GET method for the API Gateway
  authorization = "NONE" # No authorization required for this method
}

# Lambda Integration for GET method
resource "aws_api_gateway_integration" "visitor_integration" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_api.id
  resource_id             = aws_api_gateway_resource.visitor_resource.id
  http_method             = aws_api_gateway_method.visitor_get_method.http_method
  integration_http_method = "POST"  # POST to invoke Lambda
  type                    = "AWS_PROXY"  # AWS_PROXY passes full event to Lambda
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.visitor_count_function.arn}/invocations"
}

# Lambda permission for API Gateway invocation
resource "aws_lambda_permission" "allow_api_gateway_invocation" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_count_function.function_name
  principal     = "apigateway.amazonaws.com"
}

# API Gateway Stage (separate from Deployment)
resource "aws_api_gateway_stage" "visitor_stage" {
  stage_name   = "production"
  rest_api_id  = aws_api_gateway_rest_api.visitor_api.id
  deployment_id = aws_api_gateway_deployment.visitor_deployment.id
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "visitor_deployment" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  depends_on  = [aws_api_gateway_integration.visitor_integration]
}


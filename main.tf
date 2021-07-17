provider "aws" { region = "us-west-2" }

#create lambda role
resource "aws_iam_role" "lambda_role" {
  name               = "${var.owner}-${var.project}_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    tag-key = "${var.owner}-${var.project}"
  }
}

# create policy doc
resource "aws_iam_role_policy" "lambda_role_policy" {
  name   = "${var.owner}-${var.project}-${var.lambdaName}-policy"
  role   = aws_iam_role.lambda_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

data "archive_file" "lambda_archive" {
  type        = "zip"
  source_file = var.payload
  output_path = "./files/lambda.zip"
}

resource "aws_lambda_function" "lambda_function" {
  filename         = "${var.filesPath}/lambda.zip"
  function_name    = var.lambdaName
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  source_code_hash = data.archive_file.lambda_archive.output_base64sha256
  runtime          = var.runtime
}

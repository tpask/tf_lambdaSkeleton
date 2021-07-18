provider "aws" { region = "us-west-2" }
# **** these codes deals with S3 ####
data "aws_caller_identity" "current" {}


locals {
  #path to zippedFile`
  zippedFilePath = "${var.filesPath}/${var.zippedFileName}"
  s3Bucket       = "${data.aws_caller_identity.current.account_id}-terraform"
  key            = "${var.lambdaName}/${var.zippedFileName}"
  #lambdaZippedFile = var.useS3 ?
}

#create S3 bucket if it does not exists - run only if useS3 var is set to true
resource "null_resource" "createS3" {
  count = var.useS3 ? 1 : 0
  provisioner "local-exec" {
    command = "aws s3 ls s3://${local.s3Bucket} 2>/dev/null; if [ $? -eq 254 ]; then aws s3 mb s3://${local.s3Bucket}; fi"
  }
}

# copy zip file to s3 bucket
resource "aws_s3_bucket_object" "copyZippedFile" {
  count      = var.useS3 ? 1 : 0
  bucket     = local.s3Bucket
  key        = local.key
  source     = data.archive_file.lambda_archive.output_path
  etag       = filemd5("${local.zippedFilePath}")
  depends_on = [null_resource.createS3]
}

# *** end S3 section

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
  output_path = "${var.filesPath}/${var.zippedFileName}"
}

resource "aws_lambda_function" "lambda_function_noS3" {
  count            = var.useS3 ? 0 : 1
  filename         = data.archive_file.lambda_archive.output_path
  function_name    = var.lambdaName
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  source_code_hash = data.archive_file.lambda_archive.output_base64sha256
  runtime          = var.runtime
}

resource "aws_lambda_function" "lambda_function_S3" {
  count            = var.useS3 ? 1 : 0
  s3_bucket        = local.s3Bucket
  s3_key           = local.key
  function_name    = var.lambdaName
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  source_code_hash = var.zippedFileName
  runtime          = var.runtime
  depends_on       = [aws_s3_bucket_object.copyZippedFile]
}

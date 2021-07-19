# create S3 if not exists
variable "sourceZippedFile" {
  default     = ""
  description = "full path of the source zipped file.  e.g ./files/lambda.zip"
}

variable "zippedFileName" {
  default = ""
}

variable "s3Bucket" {
  default = ""
}

variable "key" {
  default = ""
}

resource "null_resource" "createS3" {
  provisioner "local-exec" {
    command = "aws s3 ls s3://${var.s3Bucket} 2>/dev/null; if [ $? -eq 254 ]; then aws s3 mb s3://${var.s3Bucket}; fi"
  }
}

# copy zip file to s3 bucket
resource "aws_s3_bucket_object" "copyZippedFile" {
  bucket     = var.s3Bucket
  key        = var.key
  source     = var.sourceZippedFile
  etag       = filemd5("${var.sourceZippedFile}")
  depends_on = [null_resource.createS3]
}

resource "random_id" "abril_bucket_suffix" {
  byte_length = 4
  
}

resource "aws_s3_bucket" "abril_bucket" {
  bucket = "abril-bucket-${random_id.abril_bucket_suffix.hex}"
  
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.abril_bucket.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
  
}

resource "aws_s3_bucket_policy" "public_policy" {
  depends_on = [aws_s3_bucket_public_access_block.public_access_block]

  bucket = aws_s3_bucket.abril_bucket.id

  policy = jsonencode({
   
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.abril_bucket.arn}/*"
      }
    ]
  })

  
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.abril_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
  
}

output "s3_endpoint" {
  value = aws_s3_bucket_website_configuration.website_config.website_endpoint
  description = "S3 endpoint"
  
}

resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/website", "**")

  bucket = aws_s3_bucket.abril_bucket.id
  key = each.value
  source = "${path.module}/website/${each.value}"

  content_type = lookup({
    "html" = "text/html"

  }, regex("[^.]+$", each.value), "application/octet-stream")

}
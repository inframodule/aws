# KMS-encrypted bucket example

Creates a versioned bucket using a customer-managed KMS key and S3 Bucket Keys. Current objects transition to Glacier Instant Retrieval after 90 days, noncurrent versions expire after one year, and incomplete multipart uploads are removed after seven days.

```shell
terraform init
terraform plan \
  -var='bucket_name=replace-with-a-globally-unique-name' \
  -var='kms_key_arn=arn:aws:kms:us-east-1:123456789012:key/example'
```

# Basic secure bucket example

Creates a private, ACL-disabled, versioned, SSE-S3 encrypted bucket. The only lifecycle action aborts incomplete multipart uploads after seven days; objects are never expired implicitly.

```shell
terraform init
terraform plan -var='bucket_name=replace-with-a-globally-unique-name'
```

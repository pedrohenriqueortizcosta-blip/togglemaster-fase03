# Bootstrap

This tiny, standalone Terraform config manages the **remote state backend itself**
(the S3 bucket that `../backend.tf` points at). It intentionally does NOT use an
S3 backend — a bucket can't hold the state that describes its own creation, so
this config uses local state (`terraform.tfstate` in this folder, gitignored).

It is expected to be applied once, rarely touched again, and its state kept
only on the machine(s) of whoever administers the AWS account (or migrated to
a tiny separate backend of its own later, if you want to get precious about it).

## Resources managed here

- `aws_s3_bucket.tfstate` — the bucket (`togglemaster-tfstate-108101918154`)
- `aws_s3_bucket_versioning` — versioning enabled, so a bad `apply` can't
  silently destroy the previous known-good state
- `aws_s3_bucket_server_side_encryption_configuration` — AES256 at rest
- `aws_s3_bucket_public_access_block` — blocks all public ACLs/policies

## First-time setup

The bucket does not exist yet — this config creates it from scratch:

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

From then on, changes to the bucket's hardening (versioning, encryption,
public access block) go through this config instead of ad-hoc `aws s3api` calls.

If the bucket ever gets created out-of-band again in the future (e.g. someone
runs a manual `aws s3api create-bucket`), bring it back under management with
`terraform import aws_s3_bucket.tfstate <bucket-name>` instead of re-applying.

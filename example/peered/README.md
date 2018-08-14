# VPC peered with a Private Space

## Usage

```bash
terraform apply \
  -var name=my-project \
  -var heroku_email=name@example.com \
  -var heroku_api_key=wwwww \
  -var heroku_enterprise_team=my-team \
  -var aws_access_key=xxxxx \
  -var aws_secret_key=yyyyy \
  -var aws_region=us-west-2
```
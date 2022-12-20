# Local

1. Install Docker, Start Docker app

2. `docker-compose up`

3. open http://0.0.0.0:3000/

# Deploy

1. Setup [Terraform State](https://github.com/jottenlips/terraform-state-s3-backend-example)

2. Spin up infrastructure

Note: this is using the default_vpc

```
terraform init
terraform plan
terraform apply
```

3. Push your Docker image to ECR

Go to this URL, view push commands

Note: replace account id

https://us-east-1.console.aws.amazon.com/ecr/repositories/private/accountid/rocket-ecr-repo?region=us-east-1

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin accountid.dkr.ecr.us-east-1.amazonaws.com
```

```
docker build -t rocket-ecr-repo .
```

```
docker tag rocket-ecr-repo:latest accountid.dkr.ecr.us-east-1.amazonaws.com/rocket-ecr-repo:latest
```

```
docker push accountid.dkr.ecr.us-east-1.amazonaws.com/rocket-ecr-repo:latest
```

# Destroy

Delete the latest image in ECR

```
terraform destroy
```

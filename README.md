# Local

1. Install Docker, Start Docker app

2. `docker-compose up`

3. open http://localhost:8000/

# Deploy

> - You need an AWS account for this

1. Setup [Terraform State](https://github.com/jottenlips/terraform-state-s3-backend-example)

2. Spin up infrastructure

> - Spins up VPC, NAT, IGW, security groups, ECS, ALB, and ECR to push your docker image to.

```
terraform init
terraform plan
terraform apply
```

This should output a url like

```
alb_url = "http://rocket-app-lb-105361214.us-east-1.elb.amazonaws.com"
```

Save it for later.

3. Push your Docker image to ECR

Go to this URL, view push commands

> - Note: replace account id

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

Once the docker image is up and the ECR tasks are done deploying you can open up your Rocket app

```
alb_url = "http://rocket-app-lb-105361214.us-east-1.elb.amazonaws.com"
```

# Destroy

Delete the latest image in ECR

```
terraform destroy
```

### Benefits of ECS / Docker / Terraform

With these technologies we can deploy apps written in any language and can scale horizontally and vertically. Say you had a Flask app also running in a docker container, you could use this terraform config to get it deployed to ECS quickly and scale the memory/cpu to what you need as well as the number of desired instances. You could also add an autoscaling group if you desire.

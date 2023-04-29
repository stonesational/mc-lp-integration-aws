# MC JB Custom Activity Connector (AWS)
This will allow the hosting of a SF Marketing Cloud Journey Builder Custom Activity on AWS


## Pre-requisites
1. [Install aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
2. [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
3. [Install Quarkus](https://quarkus.io/get-started/)
4. [Install Docker (Desktop)](https://docs.docker.com/desktop/)
5. [Install IntelliJ (Recommend Ultimate on the free trial)](https://www.jetbrains.com/help/idea/installation-guide.html)
6. Install JDK >= 17 (Whichever you like. Or have IntelliJ download it for you)
7. Open IntelliJ and add this repo as a project
8. `aws configure` to set up your aws credentials
9. from /infrastructure run `terraform init`


## Infrastructure

### Create Infrastructure
From /infrastructure run:
1. `terraform plan -out=plan.out`
2. `terraform apply plan.out`

### Destroy Infrastructure
From /infrastructure run: `terraform destroy`

## Running locally
1. IntelliJ -> Run
2. Customer Activity Config UI: [http://localhost:8080/index.html](http://localhost:8080/index.html)
3. API: [http://localhost:8080/api/execute](http://localhost:8080/api/execute)

## Deploying to AWS
1. run: /deploy.sh
2. Customer Activity UI: [https://navomi.jasonstone.us/index.html](https://navomi.jasonstone.us/)
3. API: [https://navomi.jasonstone.us/api/execute](https://navomi.jasonstone.us/api/execute)

Note: Non-linux-based Operating System users will need to port shell scripts on their own dime. You made your choice ;-) 

## Resources
1. If you want to learn more about Quarkus, please visit its website: https://quarkus.io/ .
2. [Reactive RESTful Web Services](https://quarkus.io/guides/getting-started-reactive#reactive-jax-rs-resources)

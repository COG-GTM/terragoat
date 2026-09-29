# TerraGoat - Vulnerable Terraform Infrastructure

[![Maintained by Bridgecrew.io](https://img.shields.io/badge/maintained%20by-bridgecrew.io-blueviolet)](https://bridgecrew.io/?utm_source=github&utm_medium=organic_oss&utm_campaign=terragoat)
[![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/bridgecrewio/terragoat/general)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=bridgecrewio%2Fterragoat&benchmark=INFRASTRUCTURE+SECURITY)
[![CIS Azure](https://www.bridgecrew.cloud/badges/github/bridgecrewio/terragoat/cis_azure)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=bridgecrewio%2Fterragoat&benchmark=CIS+AZURE+V1.1)
[![CIS GCP](https://www.bridgecrew.cloud/badges/github/bridgecrewio/terragoat/cis_gcp)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=bridgecrewio%2Fterragoat&benchmark=CIS+GCP+V1.1)
[![CIS AWS](https://www.bridgecrew.cloud/badges/github/bridgecrewio/terragoat/cis_aws)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=bridgecrewio%2Fterragoat&benchmark=CIS+AWS+V1.2)
[![PCI](https://www.bridgecrew.cloud/badges/github/bridgecrewio/terragoat/pci)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=bridgecrewio%2Fterragoat&benchmark=PCI-DSS+V3.2)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.12.0-blue.svg) 
[![slack-community](https://img.shields.io/badge/Slack-4A154B?style=plastic&logo=slack&logoColor=white)](https://slack.bridgecrew.io/)


TerraGoat is Bridgecrew's "Vulnerable by Design" Terraform repository.
![Terragoat](terragoat-logo.png)

TerraGoat is Bridgecrew's "Vulnerable by Design" Terraform repository.
TerraGoat is a learning and training project that demonstrates how common configuration errors can find their way into production cloud environments.

## Table of Contents

* [Introduction](#introduction)
* [Getting Started](#getting-started)
  * [AWS](#aws-setup)
  * [Azure](#azure-setup)
  * [GCP](#gcp-setup)
* [Checkov CI and baseline](#checkov-ci-and-baseline)
* [Contributing](#contributing)
* [Support](#support)

## Introduction

TerraGoat was built to enable DevSecOps design and implement a sustainable misconfiguration prevention strategy. It can be used to test a policy-as-code framework like [Bridgecrew](https://bridgecrew.io/?utm_source=github&utm_medium=organic_oss&utm_campaign=terragoat) & [Checkov](https://github.com/bridgecrewio/checkov/), inline-linters, pre-commit hooks or other code scanning methods.

TerraGoat follows the tradition of existing *Goat projects that provide a baseline training ground to practice implementing secure development best practices for cloud infrastructure.

## Important notes

* **Where to get help:** the [Bridgecrew Community Slack](https://slack.bridgecrew.io/?utm_source=github&utm_medium=organic_oss&utm_campaign=terragoat)

Before you proceed please take a not of these warning:
> :warning: TerraGoat creates intentionally vulnerable AWS resources into your account. **DO NOT deploy TerraGoat in a production environment or alongside any sensitive AWS resources.**

## Requirements

* Terraform 0.12
* aws cli
* azure cli

To prevent vulnerable infrastructure from arriving to production see: [Bridgecrew](https://bridgecrew.io/?utm_source=github&utm_medium=organic_oss&utm_campaign=terragoat) & [checkov](https://github.com/bridgecrewio/checkov/), the open source static analysis tool for infrastructure as code.

## Getting started

### AWS Setup

#### Installation (AWS)

You can deploy multiple TerraGoat stacks in a single AWS account using the parameter `TF_VAR_environment`.

#### Create an S3 Bucket backend to keep Terraform state

```bash
export TERRAGOAT_STATE_BUCKET="mydevsecops-bucket"
export TF_VAR_company_name=acme
export TF_VAR_environment=mydevsecops
export TF_VAR_region="us-west-2"

aws s3api create-bucket --bucket $TERRAGOAT_STATE_BUCKET \
    --region $TF_VAR_region --create-bucket-configuration LocationConstraint=$TF_VAR_region

# Enable versioning
aws s3api put-bucket-versioning --bucket $TERRAGOAT_STATE_BUCKET --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption --bucket $TERRAGOAT_STATE_BUCKET --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms"
      }
    }
  ]
}'
```

#### Apply TerraGoat (AWS)

```bash
cd terraform/aws/
terraform init \
-backend-config="bucket=$TERRAGOAT_STATE_BUCKET" \
-backend-config="key=$TF_VAR_company_name-$TF_VAR_environment.tfstate" \
-backend-config="region=$TF_VAR_region"

terraform apply
```

#### Remove TerraGoat (AWS)

```bash
terraform destroy
```

#### Creating multiple TerraGoat AWS stacks

```bash
cd terraform/aws/
export TERRAGOAT_ENV=$TF_VAR_environment
export TERRAGOAT_STACKS_NUM=5
for i in $(seq 1 $TERRAGOAT_STACKS_NUM)
do
    export TF_VAR_environment=$TERRAGOAT_ENV$i
    terraform init \
    -backend-config="bucket=$TERRAGOAT_STATE_BUCKET" \
    -backend-config="key=$TF_VAR_company_name-$TF_VAR_environment.tfstate" \
    -backend-config="region=$TF_VAR_region"

    terraform apply -auto-approve
done
```

#### Deleting multiple TerraGoat stacks (AWS)

```bash
cd terraform/aws/
export TF_VAR_environment = $TERRAGOAT_ENV
for i in $(seq 1 $TERRAGOAT_STACKS_NUM)
do
    export TF_VAR_environment=$TERRAGOAT_ENV$i
    terraform init \
    -backend-config="bucket=$TERRAGOAT_STATE_BUCKET" \
    -backend-config="key=$TF_VAR_company_name-$TF_VAR_environment.tfstate" \
    -backend-config="region=$TF_VAR_region"

    terraform destroy -auto-approve
done
```

### Azure Setup

#### Installation (Azure)

You can deploy multiple TerraGoat stacks in a single Azure subscription using the parameter `TF_VAR_environment`.

#### Create an Azure Storage Account backend to keep Terraform state

```bash
export TERRAGOAT_RESOURCE_GROUP="TerraGoatRG"
export TERRAGOAT_STATE_STORAGE_ACCOUNT="mydevsecopssa"
export TERRAGOAT_STATE_CONTAINER="mydevsecops"
export TF_VAR_environment="dev"
export TF_VAR_region="westus"

# Create resource group
az group create --location $TF_VAR_region --name $TERRAGOAT_RESOURCE_GROUP

# Create storage account
az storage account create --name $TERRAGOAT_STATE_STORAGE_ACCOUNT --resource-group $TERRAGOAT_RESOURCE_GROUP --location $TF_VAR_region --sku Standard_LRS --kind StorageV2 --https-only true --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $TERRAGOAT_RESOURCE_GROUP --account-name $TERRAGOAT_STATE_STORAGE_ACCOUNT --query [0].value -o tsv)

# Create blob container
az storage container create --name $TERRAGOAT_STATE_CONTAINER --account-name $TERRAGOAT_STATE_STORAGE_ACCOUNT --account-key $ACCOUNT_KEY
```

#### Apply TerraGoat (Azure)

```bash
cd terraform/azure/
terraform init -reconfigure -backend-config="resource_group_name=$TERRAGOAT_RESOURCE_GROUP" \
    -backend-config "storage_account_name=$TERRAGOAT_STATE_STORAGE_ACCOUNT" \
    -backend-config="container_name=$TERRAGOAT_STATE_CONTAINER" \
    -backend-config "key=$TF_VAR_environment.terraform.tfstate"

terraform apply
```

#### Remove TerraGoat (Azure)

```bash
terraform destroy
```

### GCP Setup

#### Installation (GCP)

You can deploy multiple TerraGoat stacks in a single GCP project using the parameter `TF_VAR_environment`.

#### Create a GCS backend to keep Terraform state

To use terraform, a Service Account and matching set of credentials are required.
If they do not exist, they must be manually created for the relevant project.
To create the Service Account:
1. Sign into your GCP project, go to `IAM` > `Service Accounts`.
2. Click the `CREATE SERVICE ACCOUNT`.
3. Give a name to your service account (for example - `terragoat`) and click `CREATE`.
4. Grant the Service Account the `Project` > `Editor` role and click `CONTINUE`.
5. Click `DONE`.

To create the credentials:
1. Sign into your GCP project, go to `IAM` > `Service Accounts` and click on the relevant Service Account.
2. Click `ADD KEY` > `Create new key` > `JSON` and click `CREATE`. This will create a `.json` file and download it to your computer.

We recommend saving the key with a nicer name than the auto-generated one (i.e. `terragoat_credentials.json`), and storing the resulting JSON file inside `terraform/gcp` directory of terragoat.
Once the credentials are set up, create the BE configuration as follows:

```bash
export TF_VAR_environment="dev"
export TF_TERRAGOAT_STATE_BUCKET=remote-state-bucket-terragoat
export TF_VAR_credentials_path=<PATH_TO_CREDNETIALS_FILE> # example: export TF_VAR_credentials_path=terragoat_credentials.json
export TF_VAR_project=<YOUR_PROJECT_NAME_HERE>

# Create storage bucket
gsutil mb gs://${TF_TERRAGOAT_STATE_BUCKET}
```

#### Apply TerraGoat (GCP)

```bash
cd terraform/gcp/
terraform init -reconfigure -backend-config="bucket=$TF_TERRAGOAT_STATE_BUCKET" \
    -backend-config "credentials=$TF_VAR_credentials_path" \
    -backend-config "prefix=terragoat/${TF_VAR_environment}"

terraform apply
```

#### Remove TerraGoat (GCP)

```bash
terraform destroy
```

## Bridgecrew's IaC herd of goats

* [CfnGoat](https://github.com/bridgecrewio/cfngoat) - Vulnerable by design Cloudformation template
* [TerraGoat](https://github.com/bridgecrewio/terragoat) - Vulnerable by design Terraform stack
* [CDKGoat](https://github.com/bridgecrewio/cdkgoat) - Vulnerable by design CDK application
* [kustomizegoat](https://github.com/bridgecrewio/kustomizegoat) - Vulnerable by design kustomize deployment
## Checkov CI and baseline

TerraGoat is vulnerable by design, so a plain Checkov scan always fails. The [`checkov`](.github/workflows/checkov.yaml) workflow runs on every pull request and on pushes to `master`, and compares the scan against the committed baseline file [`terraform/.checkov.baseline`](terraform/.checkov.baseline). Findings recorded in the baseline (the intentional vulnerabilities) are ignored; any finding **not** in the baseline fails the build.

The baseline is a JSON list of `file` → `resource` → `check_ids` produced by Checkov itself. A finding is matched by file path, resource address and check ID, so renaming a resource or moving it to another file makes its existing findings show up as new.

Run the same check locally (use the version pinned as `CHECKOV_VERSION` in the workflow):

```bash
pip install "checkov==3.3.19"
checkov -d terraform --baseline terraform/.checkov.baseline --compact --quiet
```

### Updating the baseline

Update the baseline only when you intentionally add, rename or move a vulnerable resource, or when you bump the pinned Checkov version (new releases add checks):

```bash
# from the repository root, with the pinned checkov version installed
checkov -d terraform --create-baseline --compact --quiet > /dev/null
git diff terraform/.checkov.baseline   # review: every added check ID should be intentional
```

`--create-baseline` rewrites `terraform/.checkov.baseline` with every current finding (Checkov exits non-zero because findings exist; that is expected). Commit the updated file in the same pull request as the change that required it, and mention in the description why the new findings are intentional. If you bump Checkov, update `CHECKOV_VERSION` in `.github/workflows/checkov.yaml` in the same commit.

## Contributing

Contribution is welcomed!

We would love to hear about more ideas on how to find vulnerable infrastructure-as-code design patterns.

## Support

[Bridgecrew](https://bridgecrew.io/?utm_source=github&utm_medium=organic_oss&utm_campaign=terragoat) builds and maintains TerraGoat to encourage the adoption of policy-as-code.

If you need direct support you can contact us at [info@bridgecrew.io](mailto:info@bridgecrew.io).

## Existing vulnerabilities (Auto-Generated)

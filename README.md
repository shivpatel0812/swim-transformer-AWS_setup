## Getting Started (For reference these instructions below is what was given with the original swim-transformer code without any AWS configuration in running it) 

Clone the project

**Step 0** Install the recommended version of ![pytorch](https://pytorch.org/get-started/locally/)

pip install torch==1.11.0+cpu torchvision==0.12.0+cpu torchaudio==0.11.0 --extra-index-url https://download.pytorch.org/whl/cpu


**Step 1** 
Install mmcv-full v1.5(deprecated) using pip build wheel 
~~pip install -U openmim~~
~~mim install mmengine~~
pip install mmcv-full==1.5.0 -f https://download.openmmlab.com/mmcv/dist/cpu/torch1.11.0/index.html


If your code relies on a specific version of the submodule, you may want to check for updates from time to time without actually modifying anything at checkout. Navigate to the submodule and run (Note: the latest version of mmdetection is not compatible with the mmcv v1.5)

create a folder called prediction  
put the data to run on in the data folder 
start docker  
run with data and predictions folders mounted using:  


```bash
docker build -t swin .
docker run -v ${PWD}\data:/usr/swin/data -v ${PWD}\prediction:/usr/swin/prediction swin


```

# AWS Setup (Below our the steps to set up AWS envionrment to connect with frontend application)
# Neuron Segmentation

This project runs a Dockerized neuron segmentation model locally or through AWS ECS. The AWS workflow uses S3, SQS, Lambda, API Gateway, ECR, and ECS Fargate.

---

# AWS Setup

## Architecture

```txt
Input S3 bucket / API request
        ↓
SQS queue / API Gateway
        ↓
Lambda function
        ↓
ECS Fargate task
        ↓
Segmentation Docker container
        ↓
Output files uploaded to S3
```

## AWS Services Used

* Amazon S3
* Amazon SQS
* AWS Lambda
* Amazon ECS Fargate
* Amazon ECR
* API Gateway
* IAM
* CloudWatch Logs

---

## S3 Buckets

The backend uses three S3 buckets:

```txt
Input bucket:
input-neuron-segmentation

Output bucket:
output-neuron-segmentation

Checkpoint/config bucket:
store-epoch
```

The input bucket stores `.tif` files to process.

Expected input format:

```txt
userId/input-file-name.tif
```

Example:

```txt
abc123/sample-image.tif
```

The output bucket stores generated results:

```txt
userId/predictions/file-name.npy
userId/rois/RoiSet_file-name.zip
```

The checkpoint/config bucket stores the model files:

```txt
config.toml
epoch_50.pth
```

---

# AWS Deployment Steps

## 1. Create S3 Buckets

```bash
aws s3 mb s3://input-neuron-segmentation --region us-east-1
aws s3 mb s3://output-neuron-segmentation --region us-east-1
aws s3 mb s3://store-epoch --region us-east-1
```

Upload the model config and checkpoint files:

```bash
aws s3 cp config.toml s3://store-epoch/config.toml
aws s3 cp epoch_50.pth s3://store-epoch/epoch_50.pth
```

If the bucket names are changed, update the backend code to match the new names.

---

## 2. Create ECR Repository

Create an ECR repository to store the Docker image:

```bash
aws ecr create-repository \
  --repository-name neuron-segmentation \
  --region us-east-1
```

---

## 3. Build and Push Docker Image to ECR

Replace `ACCOUNT_ID` with the target AWS account ID.

Log in to ECR:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

Build the Docker image:

```bash
docker build -t neuron-segmentation .
```

Tag the image:

```bash
docker tag neuron-segmentation:latest ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/neuron-segmentation:latest
```

Push the image to ECR:

```bash
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/neuron-segmentation:latest
```

Original deployed image reference:

```txt
982081072285.dkr.ecr.us-east-1.amazonaws.com/neuron-segmentation:latest12
```

When deploying to a new AWS account, replace the original account ID with the new account ID.

---

## 4. Create ECS Cluster and Task Definition

Create an ECS Fargate cluster and task definition using the ECR image.

Original ECS values:

```txt
Cluster:
Neuron-Segmentation

Task definition:
run-segmentation

Container name:
segmentation
```

The ECS task should receive these environment variables from Lambda:

```txt
USER_UID
INPUT_KEY
```

If the cluster name, task definition, or container name changes, update the Lambda code to match.

The ECS task must run inside the target AWS account’s VPC. Replace any original subnet IDs or security groups with values from the new AWS account.

---

## 5. Configure SQS and S3 Trigger

Create an SQS queue.

Original queue name:

```txt
s3-input-queue
```

Configure the input S3 bucket to send object upload events to the SQS queue.

Recommended event type:

```txt
s3:ObjectCreated:*
```

Only the input bucket should trigger SQS/Lambda. The output bucket should not trigger the workflow.

---

## 6. Create Lambda Function

Create a Lambda function named:

```txt
runECSSegmentationFromS3Trigger
```

Upload the provided Lambda ZIP file as the function code.

This Lambda reads SQS messages, extracts the uploaded S3 object key, gets the user ID from the file path, and starts the ECS Fargate task.

After uploading the ZIP, configure the following in AWS:

```txt
Runtime
Handler
Lambda execution role
SQS trigger
API Gateway trigger, if needed
ECS cluster name
ECS task definition
Container name
Subnet IDs
Security groups
Region
```

The Lambda ZIP only contains the function code. It does not automatically create the SQS trigger, API Gateway trigger, IAM role, ECS task definition, or networking configuration.

---

## 7. IAM Permissions

The Lambda execution role needs permissions for:

```txt
sqs:ReceiveMessage
sqs:DeleteMessage
sqs:GetQueueAttributes
ecs:RunTask
iam:PassRole
logs:CreateLogGroup
logs:CreateLogStream
logs:PutLogEvents
```

The ECS task role needs permissions for:

```txt
s3:GetObject
s3:PutObject
s3:ListBucket
s3:HeadBucket
logs:CreateLogStream
logs:PutLogEvents
sts:GetCallerIdentity
```

Recommended S3 access:

```txt
input-neuron-segmentation:
- read/list

output-neuron-segmentation:
- read/write/list

store-epoch:
- read
```

---

## 8. API Gateway

If API access is needed, create or import the API Gateway and connect it to the Lambda function.

Original API Gateway name:

```txt
Neuron-segmentation-API
```

Make sure API Gateway has permission to invoke the Lambda function.

---

# Local Development Setup

## Getting Started

Clone the project:

```bash
git clone <REPO_URL>
cd <REPO_NAME>
```

---

## Step 0: Install PyTorch

Install the recommended CPU version of PyTorch:

```bash
pip install torch==1.11.0+cpu torchvision==0.12.0+cpu torchaudio==0.11.0 --extra-index-url https://download.pytorch.org/whl/cpu
```

---

## Step 1: Install MMCV

Install `mmcv-full` version `1.5.0`:

```bash
pip install mmcv-full==1.5.0 -f https://download.openmmlab.com/mmcv/dist/cpu/torch1.11.0/index.html
```

> Note: This project uses `mmcv-full==1.5.0`. Newer versions of MMDetection may not be compatible with this MMCV version.

The following commands are not needed for this setup:

```bash
# pip install -U openmim
# mim install mmengine
```

---

## Running Locally with Docker

Create the required folders:

```bash
mkdir data
mkdir prediction
```

Place the input files you want to process inside the `data` folder.

Start Docker, then build the Docker image:

```bash
docker build -t swin .
```

Run the container with the `data` and `prediction` folders mounted.

### Mac/Linux

```bash
docker run -v ${PWD}/data:/usr/swin/data -v ${PWD}/prediction:/usr/swin/prediction swin
```

### Windows PowerShell

```bash
docker run -v ${PWD}\data:/usr/swin/data -v ${PWD}\prediction:/usr/swin/prediction swin
```

The output files will be saved in the `prediction` folder.

---

# Security Notes

Do not commit AWS access keys, secret keys, or `.env` files to GitHub.

The backend should use the ECS task role for AWS access instead of hardcoded credentials. If credentials were committed or shared, rotate them in AWS IAM immediately.

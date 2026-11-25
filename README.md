AWS Secure VPC & CI/CD Security Pipeline (DevSecOps)
📌 Project Overview
This project demonstrates a "shift-left" security approach to cloud architecture. Instead of manually configuring resources in the AWS Console, a secure multi-tier VPC is defined using Terraform. A GitHub Actions CI/CD pipeline runs Checkov (a static analysis tool) on every commit to detect and block misconfigurations before they reach production.

🏗️ Architecture & Security Controls
The Terraform code (main.tf) deploys:

VPC & Subnets: A custom VPC (10.0.0.0/16) with a Public Subnet (Bastion) and a Private Subnet (Internal).

Internet Gateway & Route Tables: Correctly routes public traffic to the internet while keeping the private subnet isolated.

Security Groups (Least Privilege):

Public SG: Allows SSH only from my specific IP (/32), not the whole internet.

Private SG: Allows SSH only from the Public Bastion Security Group.

VPC Flow Logs: Captures all network traffic to CloudWatch for auditing and incident response.

🚨 The CI/CD Security Pipeline (Checkov)
The .github/workflows/security-scan.yml file contains a GitHub Actions workflow that runs Checkov on every push.

The Vulnerability Caught
During testing, I intentionally introduced a critical misconfiguration:

CKV_AWS_24: Security Group allowed ingress from 0.0.0.0/0 to port 22 (SSH).

The Remediation & Testing
I updated the Terraform code to restrict the CIDR block to my specific trusted IP (/32).

I configured the pipeline with soft_fail: false to test if it would block bad code. When I pushed the vulnerable code, the pipeline failed (Red X) and blocked the merge.

I fixed the code and set soft_fail: true for the final build so it warns on non-critical issues but passes.

📸 Evidence
(Insert your screenshots here:)

1. Terraform Validation:
(Screenshot of the terminal showing "Success! The configuration is valid.")

2. Pipeline Blocking Vulnerable Code (Red X):
(Screenshot of the GitHub Actions page showing the failed run for the 0.0.0.0/0 commit)

3. Pipeline Passing Secure Code (Green Check):
(Screenshot of the GitHub Actions page showing the successful run)

🚀 How to Deploy
Install Terraform.

Run terraform init.

Run terraform plan to review the architecture.

Run terraform apply to deploy to AWS (requires configured AWS credentials).

<img width="1363" height="720" alt="Screenshot 2026-11-24 171902" src="https://github.com/user-attachments/assets/3d3b5a27-ee8c-4308-b05f-d76e37a40be6" />
<img width="1360" height="609" alt="Screenshot 2026-11-25 092317" src="https://github.com/user-attachments/assets/052e08bd-204f-4c93-9ace-46b2640c4f13" />
<img width="1357" height="611" alt="Screenshot 2026-11-24 180833" src="https://github.com/user-attachments/assets/a047ff01-6a7b-436b-a7a1-2f7815a3287a" />

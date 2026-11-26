<img width="1366" height="714" alt="Screenshot 2026-11-26 110920" src="https://github.com/user-attachments/assets/c5bba12e-41a2-4df0-bcbf-9fabe6348517" />
# AWS Secure VPC & CI/CD Security Pipeline (DevSecOps)

##  Project Overview
This project demonstrates a **"shift-left" security** approach to cloud architecture. Instead of manually configuring resources in the AWS Console, a secure multi-tier VPC is defined using **Terraform**. Multiple automated security tools are integrated into a **GitHub Actions CI/CD pipeline** to detect and block misconfigurations, secrets, and vulnerabilities before they reach production.

##  Architecture & Security Controls
The Terraform code (`main.tf`) deploys:
1. **VPC & Subnets:** A custom VPC (`10.0.0.0/16`) with a Public Subnet (Bastion) and a Private Subnet (Internal).
2. **Internet Gateway & Route Tables:** Correctly routes public traffic to the internet while keeping the private subnet isolated.
3. **Security Groups (Least Privilege):**
   - **Public SG:** Allows SSH **only** from my specific IP (`/32`), not the whole internet.
   - **Private SG:** Allows SSH **only** from the Public Bastion Security Group.
4. **VPC Flow Logs:** Captures all network traffic to CloudWatch for auditing and incident response.

##  The CI/CD Security Pipeline
The pipeline consists of multiple automated security gates:

1. **Local Pre-Commit (Gitleaks):** Scans the code for hardcoded secrets *before* it is committed.
2. **IaC Scanning (Checkov):** Scans Terraform code for infrastructure misconfigurations.
3. **Secret Scanning (Gitleaks):** Runs in GitHub Actions to catch secrets in the repository.
4. **SAST (Semgrep):** Scans code for static application security vulnerabilities.
5. **Dependency Scanning (Dependabot):** Automatically alerts on outdated or vulnerable dependencies.

### The Vulnerability Caught
During testing, I intentionally introduced a critical misconfiguration:
- **`CKV_AWS_24`**: Security Group allowed ingress from **`0.0.0.0/0`** to port 22 (SSH).

### The Remediation & Testing
1. I updated the Terraform code to restrict the CIDR block to my specific trusted IP (`/32`).
2. I configured the pipeline with **`soft_fail: false`** to test if it would block bad code. When I pushed the vulnerable code, **the pipeline failed (Red X) and blocked the merge**.
3. I fixed the code and set **`soft_fail: true`** for the final build so it warns on non-critical issues but passes.

##  Evidence

**1. Local Pre-commit Secret Scanning:**
*Gitleaks successfully scanned the code locally and passed, preventing secrets from entering version control.*
<img width="1363" height="720" alt="Pre-Commit Scan" src="[PASTE_YOUR_SCREENSHOT_LINK_HERE]" />

**2. Pipeline Blocking Vulnerable Code (Red X):**
*The GitHub Actions pipeline failed when the open SSH port was introduced.*
<img width="1360" height="609" alt="Pipeline Failure" src="https://github.com/user-attachments/assets/052e08bd-204f-4c93-9ace-46b2640c4f13" />

**3. Pipeline Passing Secure Code (Green Check):**
*The pipeline passed after the vulnerability was remediated.*
<img width="1357" height="611" alt="Pipeline Success" src="https://github.com/user-attachments/assets/a047ff01-6a7b-436b-a7a1-2f7815a3287a" />

##  How to Deploy
1. Install Terraform.
2. Run `terraform init`.
3. Run `terraform plan` to review the architecture.
4. Run `terraform apply` to deploy to AWS (requires configured AWS credentials).

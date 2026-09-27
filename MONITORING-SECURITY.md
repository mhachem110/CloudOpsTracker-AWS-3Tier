# CloudOpsTracker Monitoring and Security

## CloudWatch monitoring

The platform creates one dashboard per environment showing:

- ALB request count and ALB 5XX responses
- Healthy and unhealthy ALB targets
- Auto Scaling Group EC2 CPU
- RDS CPU and free storage

It also creates five alarms:

- ALB unhealthy targets
- ALB 5XX errors
- ASG CPU >= 80%
- RDS CPU >= 80%
- RDS free storage <= 2 GiB

The alarms intentionally have no SNS/email action in this training milestone.
That keeps the infrastructure observable without adding a manual email
subscription confirmation step.

## Security CI

`security-ci.yml` adds:

1. Checkov for Terraform/IaC security scanning.
2. Trivy for repository vulnerability/misconfiguration scanning.
3. Optional SonarCloud analysis for the .NET application.

Checkov and Trivy are advisory at first (`soft_fail` / exit-code 0). This lets
us capture findings without blocking the existing training pipeline. Once the
baseline findings are reviewed, they can be converted into blocking gates.

## SonarCloud configuration

Add these GitHub repository settings to enable the SonarCloud job:

Secret:
- SONAR_TOKEN

Repository variables:
- SONAR_PROJECT_KEY
- SONAR_ORGANIZATION

Without all three values, the job reports that SonarCloud is skipped rather
than failing the PR.

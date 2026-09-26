# CloudOpsTracker - Networking Phase

This package is built on top of the working bootstrap baseline.
Do not delete or replace `infra/bootstrap` or `.github/workflows/bootstrap.yml`.

## What this phase adds

- Reusable Terraform network module
- VPC per environment
- Two Availability Zones
- Two public subnets
- Two private application subnets
- Two isolated database subnets
- Internet Gateway
- NAT Gateway design
- Public/app/database route tables
- ALB, application, and database security groups
- PR static-validation workflow
- Manual GitHub Actions plan/apply/destroy workflow

## CIDRs

- dev:   10.20.0.0/16
- stage: 10.30.0.0/16
- uat:   10.40.0.0/16
- prod:  10.50.0.0/16

Each VPC derives these /24 subnets:

- public A:       x.x.0.0/24
- public B:       x.x.1.0/24
- app private A:  x.x.10.0/24
- app private B:  x.x.11.0/24
- DB private A:   x.x.20.0/24
- DB private B:   x.x.21.0/24

Dev/stage/UAT use one NAT Gateway to control lab cost.
Prod is configured for one NAT Gateway per AZ for higher availability.
Nothing costs money until an environment is actually applied.

## One-time repository baseline sync

`workflow_dispatch` workflows are surfaced from the default branch, so this
initial networking scaffold should first be committed to `main`. This is a
one-time foundation sync, not the normal application promotion process.

From the repository root on `main`:

```powershell
git checkout main
git pull origin main
```

Copy this package into the repository root, then:

```powershell
git status
git add .
git commit -m "Add reusable Terraform networking foundation"
git push origin main
```

Now synchronize the three promotion branches so they all start with the same
workflow/module baseline:

```powershell
git checkout dev
git pull origin dev
git merge main
git push origin dev

git checkout stage
git pull origin stage
git merge main
git push origin stage

git checkout uat
git pull origin uat
git merge main
git push origin uat
```

Return to dev:

```powershell
git checkout dev
```

After this initial sync, normal changes should follow:

feature/* -> dev -> stage -> uat -> main

## First network test

GitHub -> Actions -> network -> Run workflow

Use workflow from: dev
Environment: dev
Action: plan

Review the plan first. If correct, run again:

Use workflow from: dev
Environment: dev
Action: apply

Do not deploy stage/UAT/prod yet. Their configuration is ready for later promotion.

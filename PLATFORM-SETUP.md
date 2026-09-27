# CloudOpsTracker Platform Stack

The project now uses a composed environment stack for future infrastructure.

## Why

The training environments are intentionally short-lived. If networking is
destroyed after testing, a separate database stack cannot reliably plan against
live network outputs.

The platform root solves that by composing reusable modules in one Terraform
graph and one state per environment.

```text
platform
├── network module
└── database module
```

Later phases will add EC2, ALB, Auto Scaling and observability modules to this
same platform stack.

## State

- dev/platform.tfstate
- stage/platform.tfstate
- uat/platform.tfstate
- prod/platform.tfstate

## Normal promotion

Merges run Terraform PLAN only.

```text
feature/database -> dev -> stage -> uat -> main
```

## Cost-controlled testing

Only create live infrastructure when a demonstration is needed:

```text
manual DEV apply
    -> test
    -> manual DEV destroy
```

Do not keep Stage/UAT/Prod infrastructure running simply to prove that the
Terraform code plans successfully.

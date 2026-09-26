# CloudOpsTracker bootstrap next steps

1. Copy these files into the repository root.
2. Commit and push to main.
3. GitHub -> Actions -> bootstrap -> Run workflow -> action=plan.
4. Review the plan. Do not apply until the plan is correct.
5. Run again with action=apply.
6. After apply, create GitHub Environments dev, stage, uat, prod.
7. Restrict branches: dev->dev, stage->stage, uat->uat, prod->main.
8. Add AWS_ROLE_ARN to each environment using its matching role.

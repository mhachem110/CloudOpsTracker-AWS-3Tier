# CloudOpsTracker Rollback

The `platform-deploy` workflow now supports four manual actions:

- `plan`
- `apply`
- `rollback`
- `destroy`

## What rollback does

Rollback checks out a previous commit or tag from the selected deployment
branch and runs Terraform against the SAME remote state for that environment.

This means the previous Terraform configuration becomes the desired state
again and Terraform changes only what differs.

The workflow validates that the rollback ref belongs to the history of the
selected branch. This prevents accidentally rolling DEV back to an unrelated
commit from another branch.

## Safe rollback demonstration

Use a harmless CloudWatch alarm setting so the website stays available.

1. Record the current DEV commit before the demo:

   git switch dev
   git pull
   git log -1 --oneline

   Copy the commit SHA. This is your known-good rollback ref.

2. Create a temporary demo change on feature/ec2. For example change:

   infra/modules/monitoring/main.tf

   ASG CPU alarm threshold:

   threshold = 80

   to:

   threshold = 70

3. PR feature/ec2 -> dev and merge after CI is green.

4. Run platform-deploy:
   Branch: dev
   Action: apply

5. Confirm the alarm now shows 70%.

6. Run platform-deploy again:
   Branch: dev
   Action: rollback
   rollback_ref: <the known-good DEV commit SHA copied in step 1>

7. Terraform checks out that earlier configuration, plans the difference, and
   restores the CloudWatch threshold to 80%.

8. Confirm in CloudWatch that the alarm threshold is back to 80%.

## Important

Rollback is an infrastructure-code rollback. It is not a database point-in-time
restore and it does not delete Terraform state.

For application releases, the long-term production pattern would usually roll
the ASG back to a previously versioned AMI/Launch Template release. The current
training project already creates an immutable AMI and a versioned Launch
Template, but application release version selection is not yet modeled as a
separate deployable variable.

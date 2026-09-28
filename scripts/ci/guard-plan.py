"""Reject unexpected destructive changes; print counts, never plan values."""
import json
import sys


def check(plan, action):
    changes = plan.get("resource_changes", [])
    if action == "destroy":
        return []
    # Expected release lifecycle only. Database/network/roles/ALB remain protected.
    replaceable = {"module.ec2.aws_instance.this", "module.image.aws_ami_from_instance.this",
                   "module.ec2.aws_ssm_association.readiness",
                   "module.ec2.terraform_data.readiness_verified"}
    return [r["address"] for r in changes if "delete" in r["change"]["actions"]
            and not (r["address"] in replaceable and "create" in r["change"]["actions"])]


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as stream:
        plan = json.load(stream)
    blocked = check(plan, sys.argv[2])
    print("Planned resource changes:", sum(r["change"]["actions"] != ["no-op"]
          for r in plan.get("resource_changes", [])))
    if blocked:
        print("Blocked destructive changes:", ", ".join(blocked))
        raise SystemExit(1)

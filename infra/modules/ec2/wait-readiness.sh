#!/usr/bin/env bash
set -euo pipefail

: "${AWS_REGION:?}"
: "${SOURCE_INSTANCE_ID:?}"
: "${ASSOCIATION_ID:?}"

# State Manager may report an association as created before its new target has
# executed anything. The AMI must wait for this exact instance's command result.
deadline=$((SECONDS + 2100))
echo "Waiting for readiness execution on source instance ${SOURCE_INSTANCE_ID}."

while ((SECONDS < deadline)); do
  execution_id="$(aws ssm describe-association-executions \
    --association-id "$ASSOCIATION_ID" \
    --query 'sort_by(AssociationExecutions, &CreatedTime)[-1].ExecutionId' \
    --output text)"

  if [[ -n "$execution_id" && "$execution_id" != None ]]; then
    status="$(aws ssm describe-association-execution-targets \
      --association-id "$ASSOCIATION_ID" \
      --execution-id "$execution_id" \
      --filters "Key=ResourceId,Value=$SOURCE_INSTANCE_ID" \
      --query 'AssociationExecutionTargets[0].Status' \
      --output text)"

    case "$status" in
      Success)
        echo "Source instance readiness checks passed."
        exit 0
        ;;
      Failed|TimedOut|Cancelled)
        echo "Source instance readiness execution failed: $status" >&2
        exit 1
        ;;
    esac
  fi

  sleep 10
done

echo "Timed out waiting for the source instance readiness execution." >&2
exit 1

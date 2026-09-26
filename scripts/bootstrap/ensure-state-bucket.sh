#!/usr/bin/env bash
set -euo pipefail
REGION="${AWS_REGION:?AWS_REGION must be set}"
NAME_PREFIX="${NAME_PREFIX:?NAME_PREFIX must be set}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="${NAME_PREFIX}-tfstate-${ACCOUNT_ID}"
exec 3>&1 1>&2
if aws s3api head-bucket --bucket "${BUCKET}" >/dev/null 2>&1; then
  echo "State bucket ${BUCKET} already exists."
else
  echo "Creating state bucket ${BUCKET} in ${REGION}."
  if [[ "${REGION}" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}" >/dev/null
  else
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}" --create-bucket-configuration "LocationConstraint=${REGION}" >/dev/null
  fi
  aws s3api wait bucket-exists --bucket "${BUCKET}"
fi
aws s3api put-public-access-block --bucket "${BUCKET}" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null
aws s3api put-bucket-versioning --bucket "${BUCKET}" --versioning-configuration Status=Enabled >/dev/null
aws s3api put-bucket-encryption --bucket "${BUCKET}" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' >/dev/null
echo "${BUCKET}" >&3

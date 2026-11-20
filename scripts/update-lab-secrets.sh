#!/usr/bin/env bash
# Renew the AWS Academy Learner Lab session credentials in BOTH repositories (GitHub secrets).
#
# 1. Learner Lab: "Start Lab" -> "AWS Details" -> "AWS CLI: Show" -> copy the [default] block
# 2. Paste it into ~/.aws/credentials (or any file) and run:
#      ./scripts/update-lab-secrets.sh [credentials-file]
# The values are read from the file and piped to `gh secret set` - they never appear in the
# shell history, in the command line or in this repository.
set -euo pipefail
file="${1:-$HOME/.aws/credentials}"
repos=(
  AdminGodZ/bbw-m324-biztrips-fullstack-actions-aws-backend
  AdminGodZ/bbw-m324-biztrips-fullstack-actions-aws-frontend
)
value() { awk -F' *= *' -v k="$1" '$1 == k {print $2; exit}' "$file" | tr -d '\r'; }

AWS_ACCESS_KEY_ID=$(value aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(value aws_secret_access_key)
AWS_SESSION_TOKEN=$(value aws_session_token)
for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN; do
  [ -n "$(eval "printf '%s' \"\$$name\"")" ] || { echo "Missing $name in $file" >&2; exit 1; }
done
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Check the session before distributing it.
aws sts get-caller-identity --query Arn --output text >/dev/null \
  || { echo "These credentials are not valid (lab not started or already expired)." >&2; exit 1; }

for repo in "${repos[@]}"; do
  printf '%s' "$AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID --repo "$repo"
  printf '%s' "$AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY --repo "$repo"
  printf '%s' "$AWS_SESSION_TOKEN" | gh secret set AWS_SESSION_TOKEN --repo "$repo"
  echo "Updated 3 secrets in $repo"
done
echo "Done. Re-run failed deploy jobs with: gh run rerun <run-id> --failed --repo <repo>"

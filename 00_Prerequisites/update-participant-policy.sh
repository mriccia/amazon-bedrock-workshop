#!/bin/bash

ROLE_NAME="WSParticipantRole"
POLICY_NAME="iam_policy-0"
POLICY_FILE="policy.json"

# Get the policy ARN
POLICY_ARN=$(aws iam list-attached-role-policies --role-name $ROLE_NAME \
    --query "AttachedPolicies[?PolicyName=='${POLICY_NAME}'].PolicyArn" \
    --output text)

# Get the policy version ID and save the policy document
DEFAULT_VERSION=$(aws iam get-policy --policy-arn $POLICY_ARN --query 'Policy.DefaultVersionId' --output text)

# Get the policy document and save it to a file
aws iam get-policy-version \
    --policy-arn $POLICY_ARN \
    --version-id $DEFAULT_VERSION \
    --query 'PolicyVersion.Document' \
    --output json > $POLICY_FILE

echo "Current policy has been saved to $POLICY_FILE"
echo "Making policy changes"

# Swap Claude 3 Sonnet for 3.7 Sonnet
sed -i 's/prod-6dw3qvchef7zy/prod-4dlfvry4v5hbi/g' $POLICY_FILE

# Swap Claude 3 Haiku for 3.5 Haiku
sed -i 's/prod-ozonys2hmmpeu/prod-5oba7y7jpji56/g' $POLICY_FILE

echo "Checking version count"
VERSION_COUNT=$(aws iam list-policy-versions --policy-arn $POLICY_ARN --query 'length(Versions)' --output text)

if [ "$VERSION_COUNT" -ge 5 ]; then
    echo "Policy has 5 versions. Deleting oldest non-default version..."
    OLD_VERSION=$(aws iam list-policy-versions \
        --policy-arn $POLICY_ARN \
        --query 'Versions[?IsDefaultVersion==`false`].[VersionId]' \
        --output text | head -n 1)

    aws iam delete-policy-version --policy-arn $POLICY_ARN --version-id $OLD_VERSION
fi

# Create new version and set as default
aws iam create-policy-version \
    --policy-arn $POLICY_ARN \
    --policy-document file://$POLICY_FILE \
    --set-as-default

echo "New policy version has been created and set as default"
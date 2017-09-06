#!/bin/bash

function Set-IAMPasswordPolicy {
    aws iam update-account-password-policy \
    --minimum-password-length 14 \
    --require-symbols true \
    --require-numbers true \
    --require-uppercase-characters true \
    --require-lowercase-characters true \
    --allow-users-to-change-password true \
    --max-password-age 0 \
    --password-reuse-prevention 1 \
}
#!/bin/bash
source config.sh

# start an interactive session
gcloud compute ssh --zone "$ZONE" \
"$INSTANCE_NAME" \
--project "$PROJECT_ID" \
--tunnel-through-iap

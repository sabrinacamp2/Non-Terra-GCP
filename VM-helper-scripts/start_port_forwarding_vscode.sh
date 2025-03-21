#!/bin/bash
source config.sh

# set up port forwarding in the background
gcloud compute ssh --zone "$ZONE" \
"$INSTANCE_NAME" \
--project "$PROJECT_ID" \
--tunnel-through-iap \
-- -N -f -L 2222:localhost:22

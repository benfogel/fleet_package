#!/bin/bash
set +x

export TAG=$1

envsubst < fleet-package-dev1.yaml > fleet-package-target.yaml

gcloud alpha container fleet packages describe fleet-package \
    --project fp-demo-dev1 --location us-central1

if [ $? -eq 0 ]; then
    gcloud alpha container fleet packages update fleet-package \
        --source=fleet-package-target.yaml \
        --project=fp-demo-dev1
else
    gcloud alpha container fleet packages create fleet-package \
        --source=fleet-package-target.yaml \
        --project=fp-demo-dev1
fi




#!/bin/bash
set +x

export TAG=$1

git tag $TAG
git push origin --tags

for f in *.yaml; do

    envsubst < $f > "rendered-$f"

    gcloud alpha container fleet packages describe fleet-package \
        --location us-central1 \
        #--project fp-demo-dev1

    if [ $? -eq 0 ]; then
        gcloud alpha container fleet packages update fleet-package \
            --source="rendered-$f" \
            # --project=fp-demo-dev1
    else
        gcloud alpha container fleet packages create fleet-package \
            --source="rendered-$f" \
            #--project=fp-demo-dev1
    fi

    rm "rendered-$f"
done 





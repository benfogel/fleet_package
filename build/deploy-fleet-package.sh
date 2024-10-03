#!/bin/bash
set +x

export TAG=$1

git tag $TAG
git push origin --tags

for f in *.yaml; do

    envsubst < $f > "rendered-$f"
    PROJECT_RESOURCE=$(cat "rendered-$f" | yq '.target.fleet.project' -r) # returns format of projects/PROJECT_NAME
    PROJECT=${PROJECT_RESOURCE#*/} # strips `projects/` prefix

    gcloud alpha container fleet packages describe fleet-package \
        --location us-central1 \
        --project=$PROJECT

    if [ $? -eq 0 ]; then
        # Trigger new rollout
        gcloud alpha container fleet packages update fleet-package \
            --source="rendered-$f" \
            --project=$PROJECT
    else
        # First deployment of package
        gcloud alpha container fleet packages create fleet-package \
            --source="rendered-$f" \
            --project=$PROJECT
    fi

    # Poll for rollout to complete
    STATE="PENDING"
    RELEASE_NAME=$(echo $TAG | tr . -) # releases are named the same as the tag, but with `-` instead of `.`

    while [[ "$STATE" != "COMPLETE" ]]; do
        STATE=$(gcloud alpha container fleet packages rollouts list --fleet-package \
            fleet-package --filter="release:$RELEASE_NAME" \
            --project=$PROJECT \
            --format yaml | yq '.info.state')

        sleep 5
    done

    rm "rendered-$f"
done 





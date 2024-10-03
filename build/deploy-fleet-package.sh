#!/bin/bash
set +x

export TAG=$1

git tag $TAG
git push origin --tags

for f in *.yaml; do

    envsubst < $f > "/tmp/rendered-$f" # Used to replace TAG value in manifest
    PROJECT_RESOURCE=$(cat "/tmp/rendered-$f" | yq '.target.fleet.project' -r) # returns format of projects/PROJECT_NAME
    PROJECT=${PROJECT_RESOURCE#*/} # strips `projects/` prefix

    PACKAGE_NAME_RESOURCE=$(cat "/tmp/rendered-$f" | yq '.name' -r) # returns format of projects/PROJECT_NAME/locations/REGION/fleetPackages/PACKAGE_NAME
    PACKAGE_NAME=${PACKAGE_NAME_RESOURCE##*/} # strips `projects/PROJECT_NAME/locations/REGION/fleetPackages/` prefix

    gcloud alpha container fleet packages describe $PACKAGE_NAME \
        --location us-central1 \
        --project=$PROJECT

    if [ $? -eq 0 ]; then
        # Trigger new rollout
        gcloud alpha container fleet packages update $PACKAGE_NAME \
            --source="/tmp/rendered-$f" \
            --project=$PROJECT
    else
        # First deployment of package
        gcloud alpha container fleet packages create $PACKAGE_NAME \
            --source="/tmp/rendered-$f" \
            --project=$PROJECT
    fi

    # Poll for rollout to complete
    STATE="PENDING"
    RELEASE_NAME=$(echo $TAG | tr . -) # releases are named the same as the tag, but with `-` instead of `.`

    while [[ "$STATE" != "COMPLETED" ]]; do
        echo "Waiting for rollout $RELEASE_NAME to complete..."

        STATE=$(gcloud alpha container fleet packages rollouts list --fleet-package \
            fleet-package --filter="release:$RELEASE_NAME" \
            --project=$PROJECT \
            --format yaml | yq '.info.state' -r)

        sleep 5
    done

    rm "/tmp/rendered-$f"
done 





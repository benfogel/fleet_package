#!/bin/bash

PACKAGE_FOLDER="package"
PACKAGE_PREFIX="pkg-"

echo "Building all overlays"
rm -rf "${PACKAGE_FOLDER}"
mkdir -p "${PACKAGE_FOLDER}"

# Find all directories within the overlays base
for overlay_dir in "$OVERLAYS_BASE"/*/; do
    # Extract the directory name without the trailing slash
    overlay_name="${overlay_dir%/}"
    overlay_name="${overlay_name##*/}"

    if [[ -f "$(pwd)/${OVERLAYS_BASE}/${overlay_name}/kustomization.yaml" ]]; then
        echo "Building overlay: $overlay_name" # Optional for progress updates
        if [[ ! -d "$(pwd)/config/${overlay_name}" ]]; then
            echo "Creating config directory for ${overlay_name}: $(pwd)/config/${overlay_name}"
            mkdir -p "$(pwd)/config/${overlay_name}"
        fi

        # Run the kustomize build command (KGR)
        #kustomize build ${OVERLAYS_BASE}/$overlay_name > config/$overlay_name/$overlay_name-generated.yaml
        kustomize build ${OVERLAYS_BASE}/$overlay_name > package/${PACKAGE_PREFIX}$overlay_name.yaml
    else
        echo "No '${OVERLAYS_BASE}/${overlay_name}/kustomization.yaml' file found in overlay: $overlay_name. Skipping..."
        continue
    fi
done


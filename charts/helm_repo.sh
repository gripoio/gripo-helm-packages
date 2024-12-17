#!/bin/bash

ROOT_DIR="."
OUTPUT_DIR="./packages"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Checking for updated Helm charts..."

# Find all Chart.yaml files and package only updated charts
find "$ROOT_DIR" -name "Chart.yaml" -print0 | while IFS= read -r -d '' chart; do
    chart_dir=$(dirname "$chart")
    chart_name=$(yq eval '.name' "$chart")  # Extract chart name
    chart_version=$(yq eval '.version' "$chart")  # Extract chart version
    tgz_file="$OUTPUT_DIR/${chart_name}-${chart_version}.tgz"

    # Check if the chart needs repackaging
    if [ ! -f "$tgz_file" ] || [ "$chart" -nt "$tgz_file" ]; then
        echo "Packaging updated chart: $chart_name"
        helm package "$chart_dir" --destination "$OUTPUT_DIR"
    fi
done

# Regenerate the Helm index.yaml
echo "Generating Helm repository index..."
helm repo index .

echo "Helm repository index updated successfully."

#!/bin/bash

ROOT_DIR="."
OUTPUT_DIR="./packages"
test_failed= false

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Testing each package...."

find "$ROOT_DIR" -name "Chart.yaml" -print0 | while IFS= read -r -d '' chart; do
    chart_dir=$(dirname "$chart")
    echo "Processing chart directory: $chart_dir"

    # Try block (Bash equivalent)
    result=$(helm template "$chart_dir" 2>&1)  # Capture stderr and stdout
    if [ $? -ne 0 ]; then
        # If the command failed, print the error message and exit the script
        echo "Error executing helm template for chart $chart_dir:"
        echo "$result"  # Output the error message
        test_failed=true
        exit 1  # Exit the script with a non-zero status to indicate failure
    else
        # If the command was successful, print the result
        echo "Helm package is tested for $chart_dir:"
    fi
done


if ["$test_failed"=true]; then
    echo "Exiting due to failure in helm template test."
    exit 1
fi

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

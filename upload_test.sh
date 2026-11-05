#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --mail-type=ALL
#SBATCH --mail-user=jhday@mit.edu
#SBATCH --output=Dryad_upload_PRINTOUT1.log      # Standard output
#SBATCH --error=Dryad_upload_ERROR1.log        # Standard error
###################################

set -euo pipefail

#FILE_PATH="test_doc.txt.gz"
#DRYAD_URL="https://sandbox.datadryad.org/api/v2/datasets/doi%3A10.7959%2Fdryad.kprr4xh17/files/test_doc.txt.gz"
#DRYAD_URL="https://sandbox.datadryad.org/api/v2/datasets/doi%3A10.7959%2Fdryad.kprr4xh17/files/test21gb.bin"

FILE_PATH="/Users/alin/work/test_files/Empty-file-1.txt"
DRYAD_URL="http://localhost:3000/api/v2/datasets/doi%3A10.7959%2Fdryad.5x69p8dm3/files/upload_test.txt"
DRYAD_TOKEN="7EiCERoje39Y0SGRZkEVKp3GDii628QZ4iIXAc81uTw"

if [[ -z "${DRYAD_TOKEN:-}" ]]; then
    echo "ERROR: DRYAD_TOKEN is not set."
    echo 'Before submitting, run: export DRYAD_TOKEN="your_token_here"'
    exit 1
fi


if [[ ! -f "$FILE_PATH" ]]; then
    echo "ERROR: Could not find file: $FILE_PATH"
    echo "Current directory is:"
    pwd
    exit 1
fi

echo "Starting Dryad upload..."
echo "File: $FILE_PATH"
echo "Destination: $DRYAD_URL"
echo "Started at: $(date)"

curl -s \
  -F "file=@$FILE_PATH" \
  -i -X PUT "$DRYAD_URL" \
  -H "Authorization: Bearer ${DRYAD_TOKEN}" \
  -H "Content-Type: application/binary" \
  -H "Accept: application/json"

echo
echo "Finished at: $(date)"

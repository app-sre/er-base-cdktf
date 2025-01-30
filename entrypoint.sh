#!/usr/bin/env bash
set -e

# Use /credentials as AWS credentials file if it exists
test -f /credentials && export AWS_SHARED_CREDENTIALS_FILE="/credentials"

if [[ -z "$AWS_SHARED_CREDENTIALS_FILE" ]]; then
    echo "Either AWS_SHARED_CREDENTIALS_FILE or /credentials file must be set"
    exit 1
fi

DRY_RUN=${DRY_RUN:-"True"}
ACTION=${ACTION:-"Apply"}

if [[ $DRY_RUN != "True" ]] && [[ $DRY_RUN != "False" ]]; then
    echo "Invalid DRY_RUN option: $DRY_RUN. Must be 'True' or 'False'"
    exit 1
fi

if [[ $ACTION != "Apply" ]] && [[ $ACTION != "Destroy" ]]; then
    echo "Invalid ACTION option: $ACTION. Must be 'Apply' or 'Destroy'"
    exit 1
fi

echo "Starting CDKTF: ACTION=$ACTION with DRY_RUN=$DRY_RUN"

# CDKTF output options
export CI=true
export FORCE_COLOR=${FORCE_COLOR:-"0"}
export TF_CLI_ARGS=${TF_CLI_ARGS:-"-no-color"}
export ER_OUTDIR=${ER_OUTDIR:-"/tmp/cdktf.out"}
export CDKTF_LOG_LEVEL=${CDKTF_LOG_LEVEL:-"warn"}

OUTPUT_FILE=${OUTPUT_FILE:-"/work/output.json"}
CDKTF_OUT_DIR="$ER_OUTDIR/stacks/CDKTF"
TERRAFORM_CMD="terraform -chdir=$CDKTF_OUT_DIR"
LOCK="-lock=true"
if [[ $DRY_RUN == "True" ]]; then
    LOCK="-lock=false"
fi

function run_hook() {
    local HOOK_NAME="$1"
    shift
    local HOOK_DIR="./hooks"
    local HOOK_SCRIPT=""

    # Possible extensions for the hook scripts
    local EXTENSIONS=("sh" "py")

    if [ ! -d "$HOOK_DIR" ]; then
        # no hook directory
        return 0
    fi

    # Search for a valid hook script
    for EXT in "${EXTENSIONS[@]}"; do
        if [ -x "${HOOK_DIR}/${HOOK_NAME}.${EXT}" ]; then
            HOOK_SCRIPT="${HOOK_DIR}/${HOOK_NAME}.${EXT}"
            break
        fi
    done

    if [ -z "$HOOK_SCRIPT" ]; then
        # no hook script
        return 0
    fi

    # Export variables for hooks
    export DRY_RUN

    echo "Running hook: $HOOK_NAME"
    "$HOOK_SCRIPT" "$@"
}

run_hook "pre_hook"

# CDKTF init forces the provider re-download to calculate
# Other platform provider SHAs. USing terraform to init the configuration avoids it
# This shuold be reevaluated in the future.
# https://github.com/hashicorp/terraform-cdk/issues/3622
cdktf synth --output "$ER_OUTDIR"
$TERRAFORM_CMD init

if [[ $ACTION == "Apply" ]]; then
    $TERRAFORM_CMD plan -out=plan "$LOCK"
    $TERRAFORM_CMD show -json "$CDKTF_OUT_DIR"/plan > "$CDKTF_OUT_DIR"/plan.json
    run_hook "validate_plan" "$CDKTF_OUT_DIR"/plan.json

    if [[ $DRY_RUN == "False" ]]; then
        # cdktf apply isn't reliable for now, using terraform apply instead
        $TERRAFORM_CMD apply -auto-approve "$CDKTF_OUT_DIR"/plan
        $TERRAFORM_CMD output -json > "$OUTPUT_FILE"
        run_hook "check_output" "$OUTPUT_FILE"
    fi
    run_hook "post_apply" "$CDKTF_OUT_DIR"/plan.json

elif [[ $ACTION == "Destroy" ]]; then
    if [[ $DRY_RUN == "True" ]]; then
        $TERRAFORM_CMD plan -out=plan -destroy "$LOCK"
        $TERRAFORM_CMD show -json "$CDKTF_OUT_DIR"/plan > "$CDKTF_OUT_DIR"/plan.json
        run_hook "validate_plan" "$CDKTF_OUT_DIR"/plan.json

    elif [[ $DRY_RUN == "False" ]]; then
        $TERRAFORM_CMD destroy --auto-approve
    fi
    run_hook "post_delete"
fi

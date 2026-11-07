# Source this file in a SEPARATE terminal:  source ./vertex-env.sh
# It only changes this shell. Your normal Claude Code login is not touched.

export PROJECT_ID="nam-claude-sandbox-01"          # <-- change to your project ID

export CLAUDE_CODE_USE_VERTEX=1
export ANTHROPIC_VERTEX_PROJECT_ID="$PROJECT_ID"
export CLOUD_ML_REGION=global

# Pin models to the ones you enabled in Model Garden (copy exact IDs from the cards).
# Without pins, Claude Code's Vertex default is Opus (more expensive).
export ANTHROPIC_MODEL="claude-sonnet-4-6"
export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-6"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-5@20251001"

# If a pinned model does NOT support the global endpoint, give it a region:
# export VERTEX_REGION_CLAUDE_HAIKU_4_5=us-east5
# export VERTEX_REGION_CLAUDE_4_6_SONNET=europe-west1

echo "Vertex mode ON  project=$ANTHROPIC_VERTEX_PROJECT_ID  region=$CLOUD_ML_REGION  model=$ANTHROPIC_MODEL"

#!/usr/bin/env bash
set -euo pipefail

# Usage: ...

# Install GitHub CLI https://cli.github.com/manual/installation
# Login with `gh auth login`

function validate_inputs() {
  if ! command -v gh &> /dev/null; then
    echo "GitHub CLI not found. Please install it first."
    exit 1
  fi

  if ! gh auth status &> /dev/null; then
    echo "Not authenticated with GitHub. Please run 'gh auth login' first."
    exit 1
  fi

  # Check for required project scope
  required_scope="project"
  current_scopes=$(gh auth status --show-token 2>&1 | grep -oP '(?<=scopes: ).*' | tr ',' '\n' | sed 's/ //g')

  if ! echo "$current_scopes" | grep -q "^${required_scope}$"; then
    echo "Missing required scope: $required_scope"
    echo "Attempting to refresh authentication..."
    if ! gh auth refresh -s "$required_scope"; then
      echo "Failed to refresh authentication"
      echo "You can either:"
      echo "1. Run: gh auth refresh -s $required_scope"
      echo "2. Create and use a personal access token:"
      echo "   - Create token: https://github.com/settings/tokens/new?description=Project+Access&scopes=project"
      echo "   - Export token: export GH_TOKEN=your_token_here"
      echo "   - Then re-run this script"
      exit 1
    fi
  fi

  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 <project_number> <project_file>"
    exit 1
  fi

  if [[ ! -f "$2" ]]; then
    echo "Project file not found: $2"
    exit 1
  fi
}

function get_project_info() {
  local project_number=$1
  echo "Fetching project info..."
  if ! gh project view $project_number --owner "@me" --format json | tee /dev/tty > $project_path; then
    echo "Failed to fetch project info"
    exit 1
  fi
}

function create_fields() {
  local project_number=$1
  local project_file=$2

  echo "Creating project fields..."
  fields=$(head -n1 $project_file)

  for field in $fields; do
    echo "Creating field: $field"
    if ! gh project field-create $project_number --owner "@me" --name "$field" --data-type TEXT; then
      echo "Failed to create field: $field"
      exit 1
    fi
  done
}

function create_items() {
  local project_number=$1
  local project_file=$2

  echo "Creating project items..."
  titles=$(tail -n +2 $project_file | cut -f 1)

  for title in $titles; do
    echo "Creating item: $title"
    if ! gh project item-create $project_number --owner "@me" --title "$title"; then
      echo "Failed to create item: $title"
      exit 1
    fi
  done
}

function main() {
  local project_number=${1:-2}
  local project_path=${2:-.github/blueprint.json}

  validate_inputs $project_number $project_path

  # Create Project file if it doesn't exist
  if [[ ! -f "$project_path" ]]; then
    mkdir -p $(dirname "$project_path")
    touch "$project_path"
  fi

  get_project_info $project_number
  create_fields $project_number $project_path
  create_items $project_number $project_path

  echo "Project setup completed successfully!"
}

main "$@"

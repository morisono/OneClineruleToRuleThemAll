#!/usr/bin/env bash

# Install GitHub CLI https://cli.github.com/manual/installation
# Login with `gh auth login`

function create_fields() {
  echo "Creating project's fields"
  fields=$(head -n1 $2)
  for field in $fields; do
    echo $field
    gh project field-create $1 --owner "@me" --name $field --data-type TEXT
  done
}

function create_items() {
  echo "Create project items"
  titles=$(tail -n +2 $2 | cut -f 1)
  for title in $titles; do
    echo $title
    gh project item-create $1 --owner "@me" --title $title
  done
}

# Static values
PROJECT_NO=2
TSV_PATH=.github/blueprint.tsv

# Execute functions
create_fields $PROJECT_NO $TSV_PATH
create_items $PROJECT_NO $TSV_PATH
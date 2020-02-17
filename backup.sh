#!/bin/bash

source .backup.config

display_usage() {
  echo "Backing it up"
}

backup() {
  echo "Restoring"
}

if [[ ( $# == "--help") ||  $# == "-h" || $# -le 1 ]]
	then
		display_usage
		exit 0
fi



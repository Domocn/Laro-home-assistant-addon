#!/bin/bash
# Log wrapper: prefixes a start line and runs the service. Output goes to stdout/stderr
# only, which Home Assistant already captures and rotates (no unbounded files on disk).
# Usage: log-wrapper.sh <service-name> <command> [args...]
set -e
SERVICE_NAME=$1
shift
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting $SERVICE_NAME"
exec "$@"

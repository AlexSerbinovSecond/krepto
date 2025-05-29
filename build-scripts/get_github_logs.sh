#!/bin/bash

# GitHub Actions Log Viewer with .env support
# Usage: ./get_github_logs.sh [job_id] [lines]

# Load .env file
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
    echo "✅ Loaded .env file"
else
    echo "❌ .env file not found in current directory"
    exit 1
fi

# Check if GITHUB_ACTIONS_KEY is set
if [ -z "$GITHUB_ACTIONS_KEY" ]; then
    echo "❌ GITHUB_ACTIONS_KEY not found in .env file"
    exit 1
fi

REPO="AlexSerbinov/krepto-bitcoin-fork"
JOB_ID=${1:-}
LINES=${2:-50}

# Function to get latest job info
get_latest_jobs() {
    echo "🔍 Getting latest jobs..."
    curl -s -H "Accept: application/vnd.github.v3+json" \
         -H "Authorization: token $GITHUB_ACTIONS_KEY" \
         "https://api.github.com/repos/$REPO/actions/runs?per_page=1" | \
    python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if 'workflow_runs' in data and len(data['workflow_runs']) > 0:
        run = data['workflow_runs'][0]
        print(f'Latest run: {run[\"id\"]} - {run[\"status\"]} - {run[\"conclusion\"]}')
        print(f'URL: {run[\"html_url\"]}')
        print(f'Jobs URL: {run[\"jobs_url\"]}')
    else:
        print('No workflow runs found')
except Exception as e:
    print(f'Error parsing JSON: {e}')
    "
}

# Function to get jobs for a run
get_jobs() {
    local run_id=$1
    echo "🔍 Getting jobs for run $run_id..."
    curl -s -H "Accept: application/vnd.github.v3+json" \
         -H "Authorization: token $GITHUB_ACTIONS_KEY" \
         "https://api.github.com/repos/$REPO/actions/runs/$run_id/jobs" | \
    python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if 'jobs' in data:
        for job in data['jobs']:
            status = job['status']
            conclusion = job.get('conclusion', 'N/A')
            emoji = '✅' if conclusion == 'success' else '❌' if conclusion == 'failure' else '🔄'
            print(f'{emoji} Job {job[\"id\"]}: {job[\"name\"]} - {status} - {conclusion}')
    else:
        print('No jobs found')
except Exception as e:
    print(f'Error parsing JSON: {e}')
    "
}

# Function to get logs for a specific job
get_job_logs() {
    local job_id=$1
    local lines=$2
    echo "📋 Getting logs for job $job_id (last $lines lines)..."
    curl -s -H "Accept: application/vnd.github.v3+json" \
         -H "Authorization: token $GITHUB_ACTIONS_KEY" \
         "https://api.github.com/repos/$REPO/actions/jobs/$job_id/logs" | \
    tail -n $lines
}

# Function to get latest failed job logs
get_latest_failed_logs() {
    echo "🔍 Looking for latest failed job..."
    
    # Get latest run
    local run_data=$(curl -s -H "Accept: application/vnd.github.v3+json" \
                          -H "Authorization: token $GITHUB_ACTIONS_KEY" \
                          "https://api.github.com/repos/$REPO/actions/runs?per_page=1")
    
    local run_id=$(echo "$run_data" | python3 -c "import json, sys; data = json.load(sys.stdin); print(data['workflow_runs'][0]['id'] if 'workflow_runs' in data and len(data['workflow_runs']) > 0 else '')")
    
    if [ -z "$run_id" ]; then
        echo "❌ No runs found"
        return 1
    fi
    
    echo "📋 Run ID: $run_id"
    
    # Get failed job from this run
    local job_data=$(curl -s -H "Accept: application/vnd.github.v3+json" \
                          -H "Authorization: token $GITHUB_ACTIONS_KEY" \
                          "https://api.github.com/repos/$REPO/actions/runs/$run_id/jobs")
    
    local failed_job_id=$(echo "$job_data" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if 'jobs' in data:
        for job in data['jobs']:
            if job.get('conclusion') == 'failure':
                print(f'{job[\"id\"]}')
                print(f'Failed job: {job[\"name\"]}', file=sys.stderr)
                break
except Exception as e:
    print('', file=sys.stderr)
    ")
    
    if [ -n "$failed_job_id" ]; then
        echo "🔍 Found failed job: $failed_job_id"
        get_job_logs "$failed_job_id" "$LINES"
    else
        echo "✅ No failed jobs found in latest run"
    fi
}

# Main logic
if [ -z "$JOB_ID" ]; then
    echo "🚀 No job ID provided, showing latest failed job logs..."
    get_latest_failed_logs
else
    get_job_logs "$JOB_ID" "$LINES"
fi 
#!/bin/bash
# ──────────────────────────────────────────────────
# Load Test Script for Poll App
# Sends 50 requests to /poll and shows which pod
# handled each request (demonstrates K8s load balancing)
# ──────────────────────────────────────────────────

SERVICE_URL="${1:-http://localhost:30001}"
TOTAL_REQUESTS=50
VOTE_OPTIONS=("Python" "JavaScript" "Go" "Rust")

echo "============================================="
echo "  Poll App Load Test"
echo "  Target: $SERVICE_URL/poll"
echo "  Requests: $TOTAL_REQUESTS"
echo "============================================="
echo ""

declare -A POD_COUNT

# --- Phase 1: GET /poll (read traffic) ---
echo ">>> Phase 1: Sending $((TOTAL_REQUESTS / 2)) GET requests..."
echo "---------------------------------------------"
for i in $(seq 1 $((TOTAL_REQUESTS / 2))); do
    RESPONSE=$(curl -s "$SERVICE_URL/poll")
    POD=$(echo "$RESPONSE" | grep -o '"pod":"[^"]*"' | cut -d'"' -f4)
    echo "  [$i] Pod: $POD"
    POD_COUNT[$POD]=$(( ${POD_COUNT[$POD]:-0} + 1 ))
    sleep 0.1
done

echo ""

# --- Phase 2: POST /poll?vote=<random> (write traffic) ---
echo ">>> Phase 2: Sending $((TOTAL_REQUESTS / 2)) POST votes..."
echo "---------------------------------------------"
for i in $(seq 1 $((TOTAL_REQUESTS / 2))); do
    VOTE=${VOTE_OPTIONS[$RANDOM % ${#VOTE_OPTIONS[@]}]}
    RESPONSE=$(curl -s -X POST "$SERVICE_URL/poll?vote=$VOTE")
    POD=$(echo "$RESPONSE" | grep -o '"pod":"[^"]*"' | cut -d'"' -f4)
    echo "  [$i] Pod: $POD  |  Voted: $VOTE"
    POD_COUNT[$POD]=$(( ${POD_COUNT[$POD]:-0} + 1 ))
    sleep 0.1
done

echo ""
echo "============================================="
echo "  Load Distribution Summary"
echo "============================================="
for POD in "${!POD_COUNT[@]}"; do
    echo "  $POD  →  ${POD_COUNT[$POD]} requests"
done
echo "============================================="
echo ""

# --- Final poll state from each pod ---
echo ">>> Final poll results (one request to show):"
curl -s "$SERVICE_URL/poll" | python -m json.tool 2>/dev/null || curl -s "$SERVICE_URL/poll"
echo ""

#!/bin/bash
# FORBIN CYOQ - Producer/Consumer Synchronization Adventure
# CS257 Simulation Client for Project FORBIN

API_URL="https://adventure-api-673835650363.us-west1.run.app"
ADVENTURE_NAME="forbin6"

echo "==============================="
echo "  Project FORBIN - CYOQ MODE"
echo "  Producer/Consumer Simulation"
echo "==============================="
echo "Initializing secure session with FORBIN buffer module..."
echo

# Initialize session
INIT_RESPONSE=$(curl -s -X POST "$API_URL/init" \
  -H "Content-Type: application/json" \
  -d "{\"adventure_name\": \"$ADVENTURE_NAME\"}")

SESSION_ID=$(echo "$INIT_RESPONSE" | jq -r '.session_id')

if [ -z "$SESSION_ID" ]; then
  echo "❌ Failed to start session. Check network/API availability."
  exit 1
fi

echo "✅ Session initialized! ID: $SESSION_ID"
echo "Beginning buffer management diagnostic..."
echo

# Adventure game loop
while true; do
  # Fetch current scene narration
  NARRATE_RESPONSE=$(curl -s -X POST "$API_URL/narrate" \
    -H "Content-Type: application/json" \
    -d "{\"session_id\": \"$SESSION_ID\"}")

  NARRATION=$(echo "$NARRATE_RESPONSE" | jq -r '.narrated_scene.narration')
  echo "--------------------"
  echo "$NARRATION"
  echo "--------------------"

  # Retrieve available choices
  CHOICES=$(echo "$NARRATE_RESPONSE" | jq -r '.narrated_scene.choices[]?.narration')
  CHOICE_COUNT=$(echo "$CHOICES" | wc -l)

  if [ "$CHOICE_COUNT" -eq 0 ]; then
    echo "🎯 Simulation complete. Mission terminated."
    break
  fi

  echo ">> Select a course of action:"
  i=0
  while read -r choice; do
    echo "  $i) $choice"
    i=$((i + 1))
  done <<< "$CHOICES"

  read -p "Enter your choice (or type 'quit'): " INPUT

  if [[ "$INPUT" == "quit" ]]; then
    echo "🛑 Session ended by user."
    break
  fi

  if ! [[ "$INPUT" =~ ^[0-9]+$ ]] || [ "$INPUT" -ge "$CHOICE_COUNT" ]; then
    echo "⚠️ Invalid input. Please enter a valid number."
    continue
  fi

  CHOICE_TEXT=$(echo "$NARRATE_RESPONSE" | jq -r ".narrated_scene.choices[$INPUT].original_choice_text")

  # Send selected choice
  CHOICE_RESPONSE=$(curl -s -X POST "$API_URL/choice" \
    -H "Content-Type: application/json" \
    -d "{\"session_id\": \"$SESSION_ID\", \"choice\": \"$CHOICE_TEXT\"}")

  if echo "$CHOICE_RESPONSE" | jq -e '.current_node' >/dev/null; then
    echo "✅ Decision recorded. Advancing narrative..."
  else
    echo "❌ API error. Ending session."
    break
  fi
done

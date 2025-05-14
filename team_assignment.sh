#!/bin/bash
# CS257 Text Adventure Client - team_assignment.sh

API_URL="https://adventure-api-673835650363.us-west1.run.app"
ADVENTURE_NAME="brookmere-may6-0704pm"

# Start the game
echo "Welcome to the Text Adventure!"
echo "Starting a new session..."

# Initialize session
INIT_RESPONSE=$(curl -s -X POST "$API_URL/init" \
  -H "Content-Type: application/json" \
  -d "{\"adventure_name\": \"$ADVENTURE_NAME\"}")

SESSION_ID=$(echo "$INIT_RESPONSE" | jq -r '.session_id')

if [ -z "$SESSION_ID" ]; then
  echo "Failed to start a new session. Exiting."
  exit 1
fi

echo "Session initialized! Your session ID: $SESSION_ID"
echo

# Game loop
while true; do
  # Get current scene narration
  NARRATE_RESPONSE=$(curl -s -X POST "$API_URL/narrate" \
    -H "Content-Type: application/json" \
    -d "{\"session_id\": \"$SESSION_ID\"}")

  # Display narration
  NARRATION=$(echo "$NARRATE_RESPONSE" | jq -r '.narrated_scene.narration')
  echo -e "\n--- Story ---"
  echo "$NARRATION"
  echo

  # Get and display choices
  CHOICES=$(echo "$NARRATE_RESPONSE" | jq -r '.narrated_scene.choices[]?.narration')
  CHOICE_COUNT=$(echo "$CHOICES" | wc -l)

  if [ "$CHOICE_COUNT" -eq 0 ]; then
    echo "No more choices available. The story has ended."
    break
  fi

  echo "--- Available Choices ---"
  i=0
  while read -r choice; do
    echo "$i) $choice"
    i=$((i + 1))
  done <<< "$CHOICES"

  # Read user input
  read -p "Enter your choice number (or type 'quit' to exit): " INPUT

  if [[ "$INPUT" == "quit" ]]; then
    echo "Goodbye!"
    break
  fi

  if ! [[ "$INPUT" =~ ^[0-9]+$ ]] || [ "$INPUT" -ge "$CHOICE_COUNT" ]; then
    echo "Invalid choice. Please try again."
    continue
  fi

  # Extract the selected choice text
  CHOICE_TEXT=$(echo "$NARRATE_RESPONSE" | jq -r ".narrated_scene.choices[$INPUT].original_choice_text")

  # Send the selected choice
  CHOICE_RESPONSE=$(curl -s -X POST "$API_URL/choice" \
    -H "Content-Type: application/json" \
    -d "{\"session_id\": \"$SESSION_ID\", \"choice\": \"$CHOICE_TEXT\"}")

  if echo "$CHOICE_RESPONSE" | jq -e '.current_node' >/dev/null; then
    echo "Choice sent. Continuing..."
  else
    echo "Failed to process choice. Ending game."
    break
  fi
done

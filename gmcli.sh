#!/bin/bash
# Terminal Gemini AI CLI – v4.2
# Author: mr ✨
# Description: Chat with Gemini 2.5, generate/explain/improve code, analyze files, all from your terminal.

# ========== CONFIGURATION ==========
CONFIG_DIR="$HOME/.smrtask_gemini"
CONFIG_FILE="$CONFIG_DIR/config.sh"
HISTORY_FILE="$CONFIG_DIR/history.json"
INSTRUCTIONS_FILE="$CONFIG_DIR/instructions.txt"

DEFAULT_MODEL="gemini-2.5-flash-preview-04-17"
DEFAULT_MAX_TOKENS=8192
DEFAULT_TEMPERATURE=0.7
DEFAULT_TOP_K=1
DEFAULT_TOP_P=0.95

mkdir -p "$CONFIG_DIR"
[[ -f "$INSTRUCTIONS_FILE" ]] || echo "" > "$INSTRUCTIONS_FILE"

# ========== GLOBAL STATE ==========
API_KEY=""
MODEL="$DEFAULT_MODEL"
MAX_TOKENS="$DEFAULT_MAX_TOKENS"
TEMPERATURE="$DEFAULT_TEMPERATURE"
TOP_K="$DEFAULT_TOP_K"
TOP_P="$DEFAULT_TOP_P"

declare -a CONVERSATION=()

# ========== COLORS ==========
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[1;36m"
GRAY="\033[38;5;240m"
MAGENTA="\033[0;35m"
BRIGHT_CYAN="\033[96m"

# ========== DEPENDENCIES ==========
function check_dependencies() {
  for cmd in curl jq; do
    command -v "$cmd" >/dev/null || {
      echo -e "${RED}❌ Missing dependency: $cmd${RESET}"
      exit 1
    }
  done
}

# ========== CONFIG FUNCTIONS ==========
function save_config() {
  cat > "$CONFIG_FILE" <<EOF
API_KEY="$API_KEY"
MODEL="$MODEL"
MAX_TOKENS="$MAX_TOKENS"
TEMPERATURE="$TEMPERATURE"
TOP_K="$TOP_K"
TOP_P="$TOP_P"
EOF
}

function load_config() {
  [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
}

# ========== HISTORY FUNCTIONS ==========
function save_history() {
  printf '%s\n' "${CONVERSATION[@]}" | jq -s '.' > "$HISTORY_FILE"
}

function load_history() {
  [[ -f "$HISTORY_FILE" ]] && mapfile -t CONVERSATION < <(jq -c '.[]' "$HISTORY_FILE")
}

function reset_conversation() {
  CONVERSATION=()
  save_history
  echo -e "${GREEN}🧹 Conversation cleared.${RESET}"
}

# ========== UTILS ==========
function json_escape() {
  printf '%s' "$1" | jq -aRs '.'
}

function format_text_terminal() {
  local input="$1"
  input=$(echo "$input" | sed -E 's/\*\*(.+?)\*\*/'"${BOLD}"'\1'"${RESET}"'/g')
  input=$(echo "$input" | sed -E 's/\*(.+?)\*/'"${BLUE}"'\1'"${RESET}"'/g')
  input=$(echo "$input" | sed -E 's/`([^`]+)`/'"${GRAY}"'\1'"${RESET}"'/g')
  input=$(echo "$input" | sed -z -E 's/```([^`]+)```/\n'"${GRAY}"'\1'"${RESET}"'\n/g')
  echo -e "$input"
}

function print_banner() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "╔══════════════════════════════════════════════╗"
  echo "║          Terminal Gemini AI CLI v4.2        ║"
  echo "╠══════════════════════════════════════════════╣"
  echo "║    ✨ Copilot · Chat · Summarize · Analyze   ║"
  echo "╚══════════════════════════════════════════════╝"
  echo -e "${RESET}"
}

# ========== API CALLS ==========
function build_request_body() {
  local prompt="$1"
  local instructions=$(<"$INSTRUCTIONS_FILE")
  local messages=()

  [[ -n "$instructions" ]] && {
    local esc_instr=$(json_escape "System: $instructions"); esc_instr="${esc_instr:1:-1}"
    messages+=("{\"role\":\"system\",\"parts\":[{\"text\":\"$esc_instr\"}]}")
  }

  for msg in "${CONVERSATION[@]}"; do messages+=("$msg"); done

  local esc_user=$(json_escape "$prompt"); esc_user="${esc_user:1:-1}"
  messages+=("{\"role\":\"user\",\"parts\":[{\"text\":\"$esc_user\"}]}")

  local conversation_json="["
  local first=true
  for m in "${messages[@]}"; do
    $first && conversation_json+="$m" && first=false || conversation_json+=",$m"
  done
  conversation_json+="]"

  cat <<EOF
{
  "contents": $conversation_json,
  "generationConfig": {
    "temperature": $TEMPERATURE,
    "maxOutputTokens": $MAX_TOKENS,
    "topP": $TOP_P,
    "topK": $TOP_K
  },
  "safetySettings": [
    {"category":"HARM_CATEGORY_HARASSMENT","threshold":"BLOCK_MEDIUM_AND_ABOVE"},
    {"category":"HARM_CATEGORY_HATE_SPEECH","threshold":"BLOCK_MEDIUM_AND_ABOVE"},
    {"category":"HARM_CATEGORY_SEXUALLY_EXPLICIT","threshold":"BLOCK_MEDIUM_AND_ABOVE"},
    {"category":"HARM_CATEGORY_DANGEROUS_CONTENT","threshold":"BLOCK_MEDIUM_AND_ABOVE"}
  ]
}
EOF
}

function send_request() {
  local prompt="$1"
  summarize_old_history
  local payload=$(build_request_body "$prompt")
  local url="https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY"

  local response=$(curl -sS --fail -X POST "$url" -H "Content-Type: application/json" -d "$payload") || {
    echo -e "${RED}❌ API error${RESET}"; return 1
  }

  local reply=$(echo "$response" | jq -r '.candidates[0].content.parts[]?.text // empty') || return 1
  [[ -z "$reply" ]] && { echo -e "${YELLOW}⚠️ Empty reply${RESET}"; return 1; }

  local esc_user=$(json_escape "$prompt"); esc_user="${esc_user:1:-1}"
  local esc_model=$(json_escape "$reply"); esc_model="${esc_model:1:-1}"
  CONVERSATION+=("{\"role\":\"user\",\"parts\":[{\"text\":\"$esc_user\"}]}")
  CONVERSATION+=("{\"role\":\"model\",\"parts\":[{\"text\":\"$esc_model\"}]}")
  save_history

  format_text_terminal "$reply"
  return 0
}

function send_request_no_save() {
  local prompt="$1"
  summarize_old_history
  local payload=$(build_request_body "$prompt")
  local url="https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent?key=$API_KEY"

  local response=$(curl -sS --fail -X POST "$url" -H "Content-Type: application/json" -d "$payload") || return 1
  echo "$response" | jq -r '.candidates[0].content.parts[]?.text // empty'
}

function needs_continuation() {
  local text="$1"
  local last_line=$(printf '%s\n' "$text" | grep -v '^[[:space:]]*$' | tail -1)
  [[ "$last_line" =~ \.\.\.$ || "$last_line" =~ \{$ || "$last_line" =~ \;$ ]]
}

function call_request_with_continuation() {
  local prompt="$1"
  local outfile="$2"
  > "$outfile"
  local chunk=$(send_request_no_save "$prompt") || return 1
  echo "$chunk" >> "$outfile"

  while needs_continuation "$chunk"; do
    echo -e "${YELLOW}→ Continuing output...${RESET}"
    chunk=$(send_request_no_save "Continue.") || break
    echo "$chunk" >> "$outfile"
  done

  echo -e "${GREEN}✅ Output written to $outfile${RESET}"
  return 0
}

# ========== HISTORY SUMMARIZATION ==========
function summarize_old_history() {
  local threshold=20
  local to_summarize=10
  (( ${#CONVERSATION[@]} <= threshold )) && return

  local subset=$(printf '%s\n' "${CONVERSATION[@]:0:to_summarize}" | jq -s '.')
  local text=$(echo "$subset" | jq -r '.[] | .parts[0].text' | tr '\n' ' ')
  local summary=$(send_request_no_save "Summarize the following:\n$text") || return

  unset 'CONVERSATION[0]'
  for ((i=1; i<to_summarize; i++)); do unset "CONVERSATION[i]"; done
  CONVERSATION=("${CONVERSATION[@]}")
  local esc_summary=$(json_escape "Summary: $summary"); esc_summary="${esc_summary:1:-1}"
  CONVERSATION=("{\"role\":\"system\",\"parts\":[{\"text\":\"$esc_summary\"}]}" "${CONVERSATION[@]}")
  save_history
  echo -e "${GREEN}📝 History summarized.${RESET}"
}

# ========== COPILOT CODER ==========
function coder_mode_menu() {
  while true; do
    echo -e "\n${BOLD}--- Copilot Mode ---${RESET}"
    echo "1) Generate code"
    echo "2) Explain code"
    echo "3) Improve code"
    echo "4) Back"
    read -rp "Choose: " c
    case "$c" in
      1) generate_code_file ;;
      2) explain_code_file ;;
      3) edit_code_file ;;
      4) return ;;
      *) echo -e "${YELLOW}Invalid.${RESET}" ;;
    esac
  done
}

function generate_code_file() {
  read -rp "📝 Describe the code: " desc
  read -rp "📂 Save as (filename): " fname
  call_request_with_continuation "Generate a full code file named '$fname' that: $desc" "$fname"
}

function explain_code_file() {
  read -rp "📂 Path to file: " fp
  [[ ! -f "$fp" ]] && echo -e "${RED}File not found${RESET}" && return
  send_request "Explain this code:\n\n$(<"$fp")"
}

function edit_code_file() {
  read -rp "📂 File to improve: " fp
  read -rp "✍️ What to change/add? " instr
  call_request_with_continuation "Modify this code:\n\n$(<"$fp")\n\nInstructions:\n$instr" "$fp"
}

# ========== FILE ANALYSIS ==========
function analyze_file_in_chunks() {
  read -rp "📂 File to analyze: " filepath
  [[ ! -f "$filepath" ]] && echo -e "${RED}Not found${RESET}" && return

  local chunk_size=500 total=$(wc -l <"$filepath") chunks=$(( (total + chunk_size - 1) / chunk_size ))
  local summaries=()

  for ((i=0; i<chunks; i++)); do
    local start=$((i * chunk_size + 1))
    local end=$(( (i + 1) * chunk_size )); (( end > total )) && end=$total
    local chunk=$(sed -n "${start},${end}p" "$filepath")
    local s=$(send_request_no_save "Explain lines $start-$end:\n\n$chunk")
    summaries+=("Chunk $((i+1)): $s")
  done

  send_request "Summarize this file based on chunks:\n\n${summaries[*]}"
}

# ========== CHAT ==========
function chat_loop() {
  echo -e "${BOLD}💬 Chat Mode (type 'exit' to quit)${RESET}"
  while true; do
    read -rp "You: " prompt
    [[ "$prompt" == "exit" ]] && break
    [[ -z "$prompt" ]] && continue
    send_request "$prompt"
  done
}

function show_history() {
  echo -e "${BOLD}📜 History:${RESET}"
  for msg in "${CONVERSATION[@]}"; do
    local role=$(echo "$msg" | jq -r '.role')
    local text=$(echo "$msg" | jq -r '.parts[0].text')
    [[ "$role" == "user" ]] && echo -e "${GREEN}You:${RESET} $text" || echo -e "${MAGENTA}Gemini:${RESET} $(format_text_terminal "$text")"
  done
}

# ========== MENU ==========
function main_menu() {
  print_banner
  while true; do
    echo -e "${BOLD}Main Menu${RESET}"
    echo "1) Chat"
    echo "2) View history"
    echo "3) Reset conversation"
    echo "4) Copilot Coder Mode"
    echo "5) Analyze a file"
    echo "6) Set API key"
    echo "7) Set model (now: $MODEL)"
    echo "8) Set max tokens (now: $MAX_TOKENS)"
    echo "9) Set temperature (now: $TEMPERATURE)"
    echo "10) Edit instructions"
    echo "11) Exit"
    read -rp "${BRIGHT_CYAN}Select: ${RESET}" choice
    case "$choice" in
      1) chat_loop ;;
      2) show_history ;;
      3) reset_conversation ;;
      4) coder_mode_menu ;;
      5) analyze_file_in_chunks ;;
      6) read -rp "🔐 API key: " API_KEY && save_config ;;
      7) read -rp "📦 Model: " MODEL && save_config ;;
      8) read -rp "🔢 Max tokens: " MAX_TOKENS && save_config ;;
      9) read -rp "🔥 Temperature (0.0–1.0): " TEMPERATURE && save_config ;;
      10) echo -e "✏️ Custom instructions (end Ctrl+D):"; cat > "$INSTRUCTIONS_FILE" ;;
      11) echo -e "${GREEN}👋 Bye!${RESET}"; exit 0 ;;
      *) echo -e "${YELLOW}❌ Invalid option${RESET}" ;;
    esac
    echo ""
  done
}

# ========== ENTRY ==========
check_dependencies
load_config
load_history
main_menu

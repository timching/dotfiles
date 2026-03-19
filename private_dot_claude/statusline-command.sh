#!/usr/bin/env bash
# Claude Code statusLine — Option A Minimal Geometric icons, Monokai foreground colors

input=$(cat)

# --- Extract JSON fields ---
cwd=$(echo "$input"              | jq -r '.workspace.current_dir // .cwd // ""')
# Home-shorten the full path
home_dir="$HOME"
if [ -n "$home_dir" ] && [ "${cwd#$home_dir}" != "$cwd" ]; then
  dir="~${cwd#$home_dir}"
else
  dir="$cwd"
fi
session_id=$(echo "$input"      | jq -r '.session_id // ""' | cut -c1-8)
session_name=$(echo "$input"    | jq -r '.session_name // ""')
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')
model_id=$(echo "$input"        | jq -r '.model.id // ""')
agent_name=$(echo "$input"      | jq -r '.agent.name // ""')
worktree_name=$(echo "$input"   | jq -r '.worktree.name // ""')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // ""')
used_pct=$(echo "$input"        | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input"     | jq -r '.context_window.total_input_tokens // empty')
total_output=$(echo "$input"    | jq -r '.context_window.total_output_tokens // empty')
cache_write=$(echo "$input"     | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input"      | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

# --- Git ---
git_branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null)
if [ -n "$git_branch" ]; then
  git_dirty=$(git -C "$cwd" -c gc.auto=0 status --porcelain 2>/dev/null)
fi

# --- ANSI helpers (Monokai 24-bit foreground colors, no backgrounds) ---
RESET='\033[0m'

FG_BLUE='\033[38;2;102;217;239m'   # #66D9EF — SESSION, git:(  )
FG_PURPLE='\033[38;2;174;129;255m' # #AE81FF — MODEL
FG_ORANGE='\033[38;2;253;151;31m'  # #FD971F — DIR
FG_GREEN='\033[38;2;166;226;46m'   # #A6E22E — ctx 0-49%
FG_PINK='\033[38;2;249;38;114m'    # #F92672 — git branch name, ctx 80%+
FG_YELLOW='\033[38;2;230;219;116m' # #E6DB74 — git dirty ✗, agent, worktree, ctx 50-79%

# Segment separator: double space between segments
SEP='  '

# --- Segment printer ---
# Usage: seg FG_COLOR "icon text"
seg() {
  local fg="$1"
  local text="$2"
  printf "${fg}${text}${RESET}${SEP}"
}

# --- DIR + GIT (position 0, no leading whitespace, git inline robbyrussell style) ---
printf "${FG_ORANGE}${dir}${RESET}"
if [ -n "$git_branch" ]; then
  if [ -n "$git_dirty" ]; then
    printf " ${FG_BLUE}git:(${FG_PINK}${git_branch}${FG_BLUE})${RESET} ${FG_YELLOW}✗${RESET}"
  else
    printf " ${FG_BLUE}git:(${FG_PINK}${git_branch}${FG_BLUE})${RESET}"
  fi
fi
printf "${SEP}"

# --- MODEL + CONTEXT + COST segment (always shown, parens only after first API call) ---
if [ -n "$model_id" ]; then
  if [ -n "$used_pct" ] && [ -n "$total_input" ] && [ -n "$total_output" ]; then
    used_int=$(printf "%.0f" "$used_pct")
    if [ "$used_int" -ge 80 ]; then
      ctx_fg="$FG_PINK"
    elif [ "$used_int" -ge 50 ]; then
      ctx_fg="$FG_YELLOW"
    else
      ctx_fg="$FG_GREEN"
    fi

    # Pick pricing tier based on model id (per 1M tokens)
    case "$model_id" in
      *opus*)
        price_in=15.00; price_out=75.00; price_cw=18.75; price_cr=1.50 ;;
      *haiku*)
        price_in=0.80;  price_out=4.00;  price_cw=1.00;  price_cr=0.08 ;;
      *)  # sonnet and everything else
        price_in=3.00;  price_out=15.00; price_cw=3.75;  price_cr=0.30 ;;
    esac

    # Cost = (total_input * in_price + total_output * out_price
    #         + cache_write * cw_price + cache_read * cr_price) / 1_000_000
    cost=$(awk "BEGIN {
      printf \"%.2f\", \
        ($total_input  * $price_in  + \
         $total_output * $price_out + \
         $cache_write  * $price_cw  + \
         $cache_read   * $price_cr) / 1000000
    }")

    printf "${FG_PURPLE}⟡ ${model_id} ${ctx_fg}(${used_int}%%, \$${cost})${RESET}${SEP}"
  else
    seg "$FG_PURPLE" "⟡ ${model_id}"
  fi
fi

# --- WORKTREE segment (conditional) ---
if [ -n "$worktree_name" ]; then
  worktree_text="⋈ ${worktree_name}"
  if [ -n "$worktree_branch" ]; then
    worktree_text="${worktree_text}·${worktree_branch}"
  fi
  seg "$FG_YELLOW" "$worktree_text"
fi

# --- AGENT segment (conditional) ---
if [ -n "$agent_name" ]; then
  seg "$FG_YELLOW" "⬡ ${agent_name}"
fi

# ============== LINE 2 ==============
printf "\n"

# --- SESSION segment — name · id · duration ---
# Duration from transcript birth/mtime
duration_str=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  start_ts=$(stat -f "%SB" -t "%s" "$transcript_path" 2>/dev/null)
  if [ -z "$start_ts" ]; then
    start_ts=$(stat -f "%m" "$transcript_path" 2>/dev/null)
  fi
  if [ -n "$start_ts" ]; then
    now_ts=$(date +%s)
    elapsed=$(( now_ts - start_ts ))
    elapsed=$(( elapsed < 0 ? 0 : elapsed ))
    hours=$(( elapsed / 3600 ))
    mins=$(( (elapsed % 3600) / 60 ))
    if [ "$hours" -gt 0 ]; then
      duration_str="${hours}h${mins}m"
    else
      duration_str="${mins}m"
    fi
  fi
fi

# Assemble: ⊡ [name · ] id · duration
if [ -n "$duration_str" ] || [ -n "$session_id" ]; then
  printf "${FG_BLUE}⊡ "
  if [ -n "$session_name" ]; then
    printf "${session_name} · "
  fi
  printf "${session_id}"
  if [ -n "$duration_str" ]; then
    printf " · ${duration_str}"
  fi
  printf "${RESET}${SEP}"
fi

# --- USAGE QUOTA segment (Pro/Max only, cached 5min) ---
USAGE_CACHE="$HOME/.claude/.usage-cache.json"
USAGE_TTL=300  # 5 minutes

# Try to get OAuth token from macOS Keychain
usage_token=""
usage_pct=""
usage_reset=""
keychain_json=$(/usr/bin/security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
if [ -n "$keychain_json" ]; then
  usage_token=$(echo "$keychain_json" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
fi

if [ -n "$usage_token" ]; then
  # Check cache freshness
  need_fetch=1
  if [ -f "$USAGE_CACHE" ]; then
    cache_ts=$(jq -r '.timestamp // 0' "$USAGE_CACHE" 2>/dev/null)
    now_ts=$(date +%s)
    age=$(( now_ts - cache_ts ))
    if [ "$age" -lt "$USAGE_TTL" ]; then
      need_fetch=0
      usage_pct=$(jq -r '.five_hour // empty' "$USAGE_CACHE" 2>/dev/null)
      usage_reset=$(jq -r '.five_hour_reset // empty' "$USAGE_CACHE" 2>/dev/null)
    fi
  fi

  # Fetch from API if cache is stale
  if [ "$need_fetch" -eq 1 ]; then
    api_resp=$(curl -s --max-time 5 \
      -H "Authorization: Bearer ${usage_token}" \
      -H "anthropic-beta: oauth-2025-04-20" \
      "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
    if [ -n "$api_resp" ]; then
      five_util=$(echo "$api_resp" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
      five_reset=$(echo "$api_resp" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
      if [ -n "$five_util" ]; then
        usage_pct=$(printf "%.0f" "$five_util")
        usage_reset="$five_reset"
        now_ts=$(date +%s)
        printf '{"timestamp":%d,"five_hour":%s,"five_hour_reset":"%s"}\n' \
          "$now_ts" "$usage_pct" "$usage_reset" > "$USAGE_CACHE"
      fi
    fi
  fi

  # Render bar if we have data
  if [ -n "$usage_pct" ]; then
    if [ "$usage_pct" -ge 90 ]; then
      bar_fg="$FG_PINK"
    elif [ "$usage_pct" -ge 75 ]; then
      bar_fg="$FG_YELLOW"
    else
      bar_fg="$FG_BLUE"
    fi

    # Build 10-char bar: ▪▪▪·······
    filled=$(( usage_pct * 10 / 100 ))
    empty=$(( 10 - filled ))
    bar=""
    i=0; while [ "$i" -lt "$filled" ]; do bar="${bar}▪"; i=$((i+1)); done
    i=0; while [ "$i" -lt "$empty" ];  do bar="${bar}·"; i=$((i+1)); done

    # Format reset time as relative + absolute local time
    reset_str=""
    if [ -n "$usage_reset" ]; then
      reset_epoch=$(TZ=UTC date -jf "%Y-%m-%dT%H:%M:%S" "${usage_reset%%.*}" +%s 2>/dev/null)
      if [ -n "$reset_epoch" ]; then
        now_ts=$(date +%s)
        remain=$(( reset_epoch - now_ts ))
        # Absolute reset time in local timezone (e.g., "4:05pm HKT")
        reset_clock=$(date -jf "%s" "$reset_epoch" "+%-I:%M%p %Z" 2>/dev/null | sed 's/AM/am/;s/PM/pm/')
        if [ "$remain" -gt 0 ]; then
          rh=$(( remain / 3600 ))
          rm=$(( (remain % 3600) / 60 ))
          if [ "$rh" -gt 0 ]; then
            reset_str=" (${rh}h ${rm}m · resets ${reset_clock})"
          else
            reset_str=" (${rm}m · resets ${reset_clock})"
          fi
        fi
      fi
    fi

    printf "${bar_fg}◔ ${bar} ${usage_pct}%%${reset_str}${RESET}"
  fi
fi

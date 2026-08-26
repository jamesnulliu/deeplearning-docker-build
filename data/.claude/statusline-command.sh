#!/bin/bash
# Status line for Claude Code inside the JNL/DL container. One row:
#
#   Model effort flags bar NN% used/size | [JNL/DL] user@host:cwd [branch]   /rc
#   \_______ session state _______/        \___ mirrors the PS1 in ~/.bashrc ___/
#
# It is one row on purpose. Claude Code draws its own footer badges (e.g.
# "bypass permissions on") in the row *below* the status line, and a script
# cannot write into that row -- so keeping this to a single line is what makes
# the terminal show two status rows in total rather than three.
#
# The tail of the row is left empty for the Remote Control badge ("/rc active",
# "/rc reconnecting", ...), which Claude Code right-aligns onto the first status
# row whenever that row leaves it space. Run the row out to the full width and
# the badge claims a whole row of its own instead.
#
# stdin carries the session JSON documented at
# https://code.claude.com/docs/en/statusline -- every field read below is
# optional, so each has a fallback and the row still renders on a fresh session
# before the first API response has populated the token counts.

input=$(cat)

# Width maths must count characters, not bytes: this image's default locale is
# POSIX, where bash measures the bar's box glyphs as 3 columns each and the
# right-hand group gets pushed off the edge. C.UTF-8 is the one UTF-8 locale the
# image is guaranteed to ship; without it, fall back to an ASCII bar.
if locale -a 2>/dev/null | grep -qiE '^C\.utf-?8$'; then
    export LC_ALL=C.UTF-8
    BAR_FULL='▓'; BAR_EMPTY='░'
else
    BAR_FULL='#'; BAR_EMPTY='-'
fi

E=$'\033'
US=$'\037'
OFF="${E}[00m"
C_ID="${E}[01;35m"      # user@host
C_DIR="${E}[01;34m"     # cwd
C_GIT="${E}[33m"        # git branch
C_MODEL="${E}[01;36m"   # model name
C_EFFORT="${E}[00;35m"  # reasoning effort
C_FAST="${E}[00;33m"    # fast mode
C_THINK="${E}[00;34m"   # extended thinking
C_SEP="${E}[00;97m"     # group separator

# Visible width: ANSI sequences removed, then counted in characters.
vis() {
    local s
    s=$(printf '%s' "$1" | sed -E "s/${E}\[[0-9;]*m//g")
    printf '%s' "${#s}"
}

# --------------------------------------------------------------- session data
# One jq pass. The separator is US (0x1f), not a tab: bash classifies tab as
# IFS *whitespace* even when IFS is set to just a tab, so runs of tabs collapse
# into one and every field after an empty one shifts up by a slot -- which
# silently mislabels e.g. "think" as the fast-mode flag. A non-whitespace
# separator keeps empty fields, and 0x1f cannot occur in any of these values.
IFS="$US" read -r dir model pct used size effort fast thinking < <(
    printf '%s' "$input" | jq -r '
        [ (.workspace.current_dir // .cwd // "")
        , (.model.display_name // "unknown")
        , (.context_window.used_percentage // 0 | floor | tostring)
        , (.context_window.total_input_tokens // 0 | tostring)
        , (.context_window.context_window_size // 0 | tostring)
        , (.effort.level // "")
        , (if .fast_mode        then "fast"  else "" end)
        , (if .thinking.enabled then "think" else "" end)
        ] | join("\u001f")'
)
pct=${pct:-0}
display_dir="${dir/#$HOME/\~}"          # mimic bash's \w

user=$(whoami)
host=$(hostname -s)

# parse_git_branch() from ~/.bashrc. --no-optional-locks so a concurrent git
# command can never make the status line block on index.lock.
git_part=""
if [ -n "$dir" ]; then
    branch=$(git --no-optional-locks -C "$dir" branch --show-current 2>/dev/null)
    [ -n "$branch" ] && git_part=" [$branch]"
fi

chroot_part=""
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi
[ -n "$debian_chroot" ] && chroot_part="($debian_chroot)"

# ------------------------------------------------------- identity group (right)
# $1 = path to display. $2 = detail: 2 full, 1 drops the constant [JNL/DL] tag,
# 0 drops the git branch as well. The tag goes first because it never varies,
# whereas the branch actually tells you something. Only narrow terminals get
# below 2.
build_ident() {
    local out=""
    [ "$2" -ge 2 ] && out+="[JNL/DL] ${chroot_part}"
    out+="${C_ID}${user}@${host}${OFF}:${C_DIR}${1}${OFF}"
    [ "$2" -ge 1 ] && out+="${C_GIT}${git_part}${OFF}"
    printf '%s' "$out"
}

# ---------------------------------------------------------- state group (left)
human() {                                # 15500 -> 16k, 1000000 -> 1.0M
    local n=${1:-0}
    if   [ "$n" -ge 1000000 ]; then awk -v n="$n" 'BEGIN{printf "%.1fM", n/1000000}'
    elif [ "$n" -ge 1000 ];    then awk -v n="$n" 'BEGIN{printf "%.0fk", n/1000}'
    else printf '%s' "$n"
    fi
}

bar_width=10
filled=$(( pct * bar_width / 100 ))
[ "$filled" -lt 0 ] && filled=0
[ "$filled" -gt "$bar_width" ] && filled=$bar_width
bar=""
for (( i = 0; i < bar_width; i++ )); do
    if [ "$i" -lt "$filled" ]; then bar+="$BAR_FULL"; else bar+="$BAR_EMPTY"; fi
done

# Green until half full, amber past 50%, red past 80% -- the point where
# compaction is close enough to be worth knowing about at a glance.
if   [ "$pct" -ge 80 ]; then C_CTX="${E}[01;31m"
elif [ "$pct" -ge 50 ]; then C_CTX="${E}[01;33m"
else                         C_CTX="${E}[01;32m"
fi

# $1 = detail level: 3 full, 2 drops the token counts, 1 drops the bar as well,
# 0 drops the effort/fast/thinking flags, leaving just the model and percentage.
build_state() {
    local out="${C_MODEL}${model}${OFF}"
    if [ "$1" -ge 1 ]; then
        [ -n "$effort" ]   && out+=" ${C_EFFORT}${effort}${OFF}"
        [ -n "$fast" ]     && out+=" ${C_FAST}${fast}${OFF}"
        [ -n "$thinking" ] && out+=" ${C_THINK}${thinking}${OFF}"
    fi
    if [ "$1" -ge 2 ]; then
        out+=" ${C_CTX}${bar} ${pct}%${OFF}"
    else
        out+=" ${C_CTX}${pct}%${OFF}"
    fi
    # Absolute counts only once the first API response has set a window size --
    # "0/0" on a fresh session is noise, not information.
    if [ "$1" -ge 3 ] && [ "${size:-0}" -gt 0 ]; then
        out+=" $(human "$used")/$(human "$size")"
    fi
    printf '%s' "$out"
}

# ------------------------------------------------------------------ compose
# COLUMNS is the *terminal* width, but Claude Code draws the status line into a
# narrower region: indented 2 columns on the left and ending 2 short of the
# right edge, matching the inset of its own footer badges. Build to the region,
# not to COLUMNS, or Claude Code truncates the tail with an ellipsis -- which
# eats the context readout, the one thing that has to stay visible.
reserve=4
cols=$(( ${COLUMNS:-80} - reserve ))
[ "$cols" -lt 20 ] && cols=${COLUMNS:-80}

# Columns held back at the right edge for the /rc badge (see the header note).
# 16 is the widest label ("/rc reconnecting"), plus a two-column gap.
badge=18
avail=$(( cols - badge ))
[ "$avail" -lt 40 ] && avail=$cols

# On a very narrow terminal even the bare model name plus percentage can exceed
# the region. Clip the name rather than let the row wrap.
max_model=$(( avail - 6 ))
if [ "$max_model" -ge 6 ] && [ "${#model}" -gt "$max_model" ]; then
    model="${model:0:$((max_model - 1))}…"
fi

SEP=" ${C_SEP}|${OFF} "
sep_w=3
min_dir=12                               # shorter than this and "…x/y" is noise

# Fit by shedding detail, most expendable first. The pairs are (state, identity)
# detail levels: the path is squeezed -- and truncated from the left, keeping
# the leaf -- before any session state is given up, because the leaf directory
# is recoverable from the prompt above while the token budget is not.
row=""
for combo in "3 2" "2 2" "1 2" "0 2" "0 1" "0 0"; do
    set -- $combo
    state=$(build_state "$1"); sw=$(vis "$state")
    fixed=$(vis "$(build_ident "" "$2")")        # identity group minus the path
    room=$(( avail - sw - sep_w - fixed ))       # columns left for the path
    if [ "$room" -ge "${#display_dir}" ]; then
        row="${state}${SEP}$(build_ident "$display_dir" "$2")"; break
    elif [ "$room" -ge "$min_dir" ]; then
        row="${state}${SEP}$(build_ident "…${display_dir: -$((room - 1))}" "$2")"; break
    fi
done

# Nothing fits: drop the identity group entirely rather than wrap.
[ -z "$row" ] && row=$(build_state 0)

printf '%s\n' "$row"

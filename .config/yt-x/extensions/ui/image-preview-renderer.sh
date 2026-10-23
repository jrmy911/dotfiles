#!/bin/sh
draw_divider() {
  ll=0
  while [ "$ll" -lt "${FZF_PREVIEW_COLUMNS:-40}" ]; do
    printf '%s─%s' "${THEME_FZF_PREVIEW_DIVIDER:-}" "${THEME_RESET:-}"
    ll=$((ll + 1))
  done
  printf '\n'
}

fzf_preview() {
  preview_width=${FZF_PREVIEW_COLUMNS:-40}
  preview_height=$(( ${FZF_PREVIEW_LINES:-24} / 2 ))
  [ "$preview_height" -le 12 ] || preview_height=12
  [ "$preview_height" -ge 1 ] || preview_height=1
  pixel_terminal=false
  case "${TERM:-}" in *ghostty*|*kitty*) pixel_terminal=true ;; esac
  if [ -n "${GHOSTTY_RESOURCES_DIR:-}${GHOSTTY_BIN_DIR:-}${KITTY_WINDOW_ID:-}" ]; then
    pixel_terminal=true
  fi
  if [ "$pixel_terminal" = true ] && command -v kitten >/dev/null 2>&1; then
    if kitten icat --clear --engine=builtin --transfer-mode=stream \
      --unicode-placeholder --stdin=no --align=left \
      --place="${preview_width}x${preview_height}@0x0" "$1"; then
      printf '\033[0m\n'
      return
    fi
  fi
  chafa --format=symbols --probe=off --animate=off --polite=on \
    --size="${preview_width}x${preview_height}" "$1"
  printf '\n'
}

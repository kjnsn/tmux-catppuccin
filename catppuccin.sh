#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

# Set path of script
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# import
# shellcheck source=./builder/module_builder.sh
source "${PLUGIN_DIR}/builder/module_builder.sh"
# shellcheck source=./builder/window_builder.sh
source "${PLUGIN_DIR}/builder/window_builder.sh"
# shellcheck source=./builder/pane_builder.sh
source "${PLUGIN_DIR}/builder/pane_builder.sh"
# shellcheck source=./utils/tmux_utils.sh
source "${PLUGIN_DIR}/utils/tmux_utils.sh"
# shellcheck source=./utils/interpolate_utils.sh
source "${PLUGIN_DIR}/utils/interpolate_utils.sh"
# shellcheck source=./utils/module_utils.sh
source "${PLUGIN_DIR}/utils/module_utils.sh"

main() {
  # options
  IFS=' ' read -r -a plugins <<<$(get_tmux_option "@dracula-plugins" "battery network weather")

  # Aggregate all commands in one array
  local tmux_commands=()

  # module directories
  local custom_path modules_custom_path modules_status_path modules_window_path modules_pane_path
  custom_path="$(get_tmux_option "@catppuccin_custom_plugin_dir" "${PLUGIN_DIR}/custom")"
  modules_custom_path=$custom_path
  modules_status_path=$PLUGIN_DIR/status
  modules_window_path=$PLUGIN_DIR/window
  modules_pane_path=$PLUGIN_DIR/pane

  # load local theme
  local theme
  local color_interpolation=()
  local color_values=()
  local temp
  theme="$(get_tmux_option "@catppuccin_flavour" "mocha")"
  # NOTE: Pulling in the selected theme by the theme that's being set as local
  # variables.
  # https://github.com/dylanaraps/pure-sh-bible#parsing-a-keyval-file
  # shellcheck source=./catppuccin-frappe.tmuxtheme
  while IFS='=' read -r key val; do
    # Skip over lines containing comments.
    # (Lines starting with '#').
    [ "${key##\#*}" ] || continue

    # '$key' stores the key.
    # '$val' stores the value.
    eval "local $key"="$val"

    # TODO: Find a better way to strip the quotes from `$val`
    temp="${val%\"}"
    temp="${temp#\"}"
    color_interpolation+=("\#{$key}")
    color_values+=("${temp}")
  done <"${PLUGIN_DIR}/themes/catppuccin_${theme}.tmuxtheme"

  # sets refresh interval to every 5 seconds
  #tmux set-option -g status-interval $show_refresh

  # set length
  tmux set-option -g status-left-length 100
  tmux set-option -g status-right-length 100

  # pane border styling
  tmux set-option -g pane-active-border-style "fg=${thm_lavender}"
  tmux set-option -g pane-border-style "fg=${thm_gray}"

  # message styling
  tmux set-option -g message-style "bg=${thm_gray},fg=${thm_fg}"

  # status bar
  tmux set-option -g status-style "bg=${thm_bg},fg=${thm_fg}"

  # windows
  tmux set-window-option -g window-status-current-format "#[bg=${thm_mauve},fg=${thm_crust}] #I #W "
  tmux set-window-option -g window-status-format "#[bg=${thm_surface0}]#[fg=${thm_fg}] #I #W "
  tmux set-window-option -g window-status-activity-style "bold"
  tmux set-window-option -g window-status-bell-style "bold"

  tmux set-option -g status-right ""

  # status module
  local status_left_separator status_right_separator status_connect_separator \
    status_fill
  status_left_separator=$(get_tmux_option "@catppuccin_status_left_separator" "")
  status_right_separator=$(get_tmux_option "@catppuccin_status_right_separator" "█")
  status_connect_separator=$(get_tmux_option "@catppuccin_status_connect_separator" "yes")
  status_fill=$(get_tmux_option "@catppuccin_status_fill" "icon")

  local status_modules_left loaded_modules_left
  status_modules_left=$(get_tmux_option "@catppuccin_status_modules_left" "")
  loaded_modules_left=$(load_modules "$status_modules_left" "$modules_custom_path" "$modules_status_path")
  tmux set-option -g status-left "$(do_color_interpolation "$loaded_modules_left")"

  local status_modules_right loaded_modules_right
  status_modules_right=$(get_tmux_option "@catppuccin_status_modules_right" "application session")
  loaded_modules_right=$(load_modules "$status_modules_right" "$modules_custom_path" "$modules_status_path")
  tmux set-option -g status-right "$(do_color_interpolation "$loaded_modules_right")"

}

main

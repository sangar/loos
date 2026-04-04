#!/bin/bash

print_with_color_cycle() {
  local text="$1"
  local delay=0.05
  local colors=(31 32 33 34 35 36)

  for ((i = 0; i < ${#text}; i++)); do
    local color_idx=$((i % ${#colors[@]}))
    echo -ne "\033[${colors[$color_idx]}m${text:$i:1}\033[0m"
    sleep $delay
  done
  echo ""
}

echo ""
print_with_color_cycle "loOS installation complete!"
echo "Reboot to enter Hyprland."
echo ""

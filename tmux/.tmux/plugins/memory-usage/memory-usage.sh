#!/usr/bin/env bash

main() {
  used_mem=$(top -l 1 -s 0 | grep PhysMem | awk '{print $2}')
  physical_mem=$(sysctl -n hw.memsize | awk '{printf "%d", $1/1024/1024/1024}')
  swap_mem=$(sysctl -n vm.swapusage | awk '/used/{printf "%.2f", $6/1024}')
  
  echo "${used_mem}/${physical_mem}G (swap ${swap_mem}G)"
}

main

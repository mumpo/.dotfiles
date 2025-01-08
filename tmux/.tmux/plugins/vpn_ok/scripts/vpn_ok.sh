#!/usr/bin/env bash

vpn_ok() {
  if netstat -nr -f inet | grep utun > /dev/null; then
    echo "ok"
  else
    echo "ko"
  fi
}

main() {
  vpn_ok
}

main

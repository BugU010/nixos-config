#!/usr/bin/env bash
set -u

MOUNT="/"
THRESHOLD_GIB=10

NTFY_URL="https://ntfy.yexi.space:8443/alert"
NTFY_USER="automation"
NTFY_PASS_FILE="/etc/nixos/secrets/ntfy-password.txt"

UNALLOC_BYTES=$(btrfs filesystem usage -b "$MOUNT" 2>/dev/null \
  | awk '/Device unallocated:/ {print $3}')

if [[ -z "${UNALLOC_BYTES:-}" ]]; then
  logger -t btrfs-alert "无法解析 Unallocated 数值，挂载点: $MOUNT"
  exit 1
fi

UNALLOC_GIB=$(( UNALLOC_BYTES / 1024 / 1024 / 1024 ))

if (( UNALLOC_GIB >= THRESHOLD_GIB )); then
  exit 0
fi

MSG="Btrfs Unallocated 告警: ${UNALLOC_GIB} GiB (阈值: ${THRESHOLD_GIB} GiB, 挂载点: ${MOUNT})"
logger -t btrfs-alert "$MSG"

if [[ ! -r "$NTFY_PASS_FILE" ]]; then
  logger -t btrfs-alert "密码文件不可读: $NTFY_PASS_FILE"
  exit 1
fi
NTFY_PASS=$(<"$NTFY_PASS_FILE")

CURL_CFG=$(mktemp)
trap 'rm -f "$CURL_CFG"' EXIT
chmod 600 "$CURL_CFG"

cat > "$CURL_CFG" <<EOF
url = "$NTFY_URL"
user = "$NTFY_USER:$NTFY_PASS"
silent
show-error
fail
connect-timeout = 5
max-time = 15
retry = 3
retry-delay = 5
header = "Title: Btrfs Unallocated Alert"
header = "Priority: high"
header = "Tags: warning,floppy_disk"
data-binary = "$MSG"
EOF

if curl -K "$CURL_CFG"; then
  logger -t btrfs-alert "ntfy 推送成功"
else
  rc=$?
  logger -t btrfs-alert "ntfy 推送失败 (curl 退出码: $rc)"
  exit 1
fi

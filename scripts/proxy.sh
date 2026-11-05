# proxy.sh 用法:
#   ./proxy.sh on                # 使用默认 IP 192.168.5.6:10808
#   ./proxy.sh on 192.168.5.8    # 指定 IP
#   ./proxy.sh off               # 关闭代理
#   ./proxy.sh status            # 查看当前代理

DEFAULT_IP="192.168.5.6"
PORT="10808"

PROXY_VARS=(http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY)

usage() {
    echo "用法: $0 {on [IP]|off|status}"
    echo "  默认 IP: $DEFAULT_IP, 端口: $PORT"
    exit 1
}

proxy_on() {
    local ip="${1:-$DEFAULT_IP}"
    export http_proxy="http://${ip}:${PORT}"
    export https_proxy="http://${ip}:${PORT}"
    export all_proxy="socks5://${ip}:${PORT}"
    export HTTP_PROXY="http://${ip}:${PORT}"
    export HTTPS_PROXY="http://${ip}:${PORT}"
    export ALL_PROXY="socks5://${ip}:${PORT}"
    echo "代理已开启: ${ip}:${PORT}"
}

proxy_off() {
    unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
    echo "代理已关闭"
}

proxy_status() {
    local found=0
    for v in "${PROXY_VARS[@]}"; do
        if [ -n "${!v}" ]; then
            echo "$v=${!v}"
            found=1
        fi
    done
    [ $found -eq 0 ] && echo "当前未设置代理"
}

case "$1" in
    on)     proxy_on "$2" ;;
    off)    proxy_off ;;
    status) proxy_status ;;
    *)      usage ;;
esac

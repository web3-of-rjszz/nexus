#!/bin/bash
set -e

BASE_CONTAINER_NAME="nexus-node"
IMAGE_NAME="nexus-node:latest"
LOG_DIR="/root/nexus_logs"

# 检查并安装 Node.js 和 pm2
function check_node_pm2() {
    # 检查是否安装了 Node.js
    if ! command -v node >/dev/null 2>&1; then
        echo "检测到未安装 Node.js，正在安装..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    fi

    # 检查是否安装了 pm2
    if ! command -v pm2 >/dev/null 2>&1; then
        echo "检测到未安装 pm2，正在安装..."
        npm install -g pm2
    fi
}

function install_nexus() {
    # 判断nexus是否已安装
    if command -v nexus-network >/dev/null 2>&1; then
        echo "nexus-network已安装"
        return
    fi

    apt-get update && apt-get install -y \
    curl \
    screen \
    bash \
    && rm -rf /var/lib/apt/lists/*

    # 自动下载安装最新版 nexus-network
    curl -sSL https://cli.nexus.xyz/ | NONINTERACTIVE=1 sh \
    && ln -sf /root/.nexus/bin/nexus-network /usr/local/bin/nexus-network
}

function run_nexus() {
    # 获取node-id
    read -p "请输入node_id:" node_id
    # 检查输入是否为纯数字，如果不是则赋默认值100
    if [[ ! "$node_id" =~ ^[0-9]+$ ]]; then
        echo "输入node_id无效，exit"
        exit 1
    fi

    # 获取并发数
    local concurrency=100
    read -p "请输入并发数量:" concurrency
    # 检查输入是否为纯数字，如果不是则赋默认值100
    if [[ ! "$concurrency" =~ ^[0-9]+$ ]]; then
        echo "输入无效，使用默认值 100"
        concurrency=100
    fi
    echo "并发数:$concurrency"

    if ! command -v nexus-network >/dev/null 2>&1; then
        echo "错误：nexus-network 未安装或不可用"
        exit 1
    fi

    nexus -X quit >/dev/null 2>&1 || true 

    echo "启动 nexus-network 节点..."
    nohup nexus-network start --node-id $node_id --max-threads $concurrency >> /root/nexus.log 2&1 &

}

check_node_pm2
install_nexus
run_nexus

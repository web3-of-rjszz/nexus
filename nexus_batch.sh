#!/bin/bash

# 服务器配置
SERVER_IP="123.4.5"
USERNAME="ubuntu"
PASSWORD='pass'

# 节点id
node_ids=("14567866" "14596194")

# 登录服务器并初始化 Tmux 会话
sshpass -p "$PASSWORD" ssh -tt "$USERNAME@$SERVER_IP" "bash -s" << REMOTE_CMD
    {   # 关闭命令回显
        set +x  
        # 下载或者更新nexus客户端
        curl https://cli.nexus.xyz/ | NONINTERACTIVE=1 sh && source ~/.bashrc
        # 清除所有 tmux终端
        tmux kill-server 2>/dev/null 
        echo "已清除所有tmux终端"
        sleep 5

        # 循环创建tmux终端,启动nexus节点
        for node_id in ${node_ids[@]}; do
            session_name="nexus_\${node_id}"
            tmux new-session -d -s "\$session_name" "nexus-network start --node-id \$node_id --max-threads 8"
            echo "节点 \$node_id 启动成功 (会话: \$session_name)"
            sleep 10
        done

        # 关键！退出远程Shell，关闭SSH连接    
        exit  
    }
REMOTE_CMD
#!/bin/bash

# 测试内存解析修复
# 用法: ./test_memory_fix.sh <PID>

PID=$1

if [ -z "$PID" ]; then
    echo "用法: $0 <PID>"
    exit 1
fi

echo "=== 测试内存解析修复 ==="
echo ""

# 模拟修复后的逻辑
OS_TYPE=$(uname -s)

if [ "$OS_TYPE" = "Darwin" ]; then
    echo "macOS系统 - 使用原有逻辑"
    top_output=$(top -pid $PID -l 1 -stats pid,cpu,mem 2>/dev/null | tail -n +13 | head -1)
    current_cpu=$(echo "$top_output" | awk '{print $2}' | sed 's/%//')
    current_mem_str=$(echo "$top_output" | awk '{print $3}')
    echo "Top输出: $top_output"
    echo "CPU: ${current_cpu}%, 内存字符串: $current_mem_str"
else
    echo "Linux系统 - 使用修复后的逻辑"
    top_output=$(top -p $PID -n 1 -b 2>/dev/null | grep "^ *$PID " | head -1)
    
    if [ -n "$top_output" ]; then
        current_cpu=$(echo "$top_output" | awk '{print $9}')
        current_mem_res=$(echo "$top_output" | awk '{print $6}')
        current_mem_mb=$((current_mem_res / 1024))
        
        echo "Top输出: $top_output"
        echo "解析结果:"
        echo "  CPU: ${current_cpu}%"
        echo "  RES: ${current_mem_res}KB"
        echo "  内存: ${current_mem_mb}MB"
    else
        echo "无法获取top输出，回退到ps命令"
        current_cpu=$(ps -p $PID -o %cpu --no-headers 2>/dev/null | tr -d ' ')
        current_mem_kb=$(ps -p $PID -o rss --no-headers 2>/dev/null | tr -d ' ')
        current_mem_mb=$((current_mem_kb / 1024))
        echo "PS结果: CPU=${current_cpu}%, 内存=${current_mem_mb}MB"
    fi
fi

echo ""
echo "=== 对比结果 ==="
ps_cpu=$(ps -p $PID -o %cpu --no-headers 2>/dev/null | tr -d ' ')
ps_mem_kb=$(ps -p $PID -o rss --no-headers 2>/dev/null | tr -d ' ')
ps_mem_mb=$((ps_mem_kb / 1024))

echo "PS命令: CPU=${ps_cpu}%, 内存=${ps_mem_mb}MB"
echo "修复后: CPU=${current_cpu}%, 内存=${current_mem_mb}MB" 
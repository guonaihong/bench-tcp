#!/bin/bash

# 调试脚本：测试top命令在Linux下的输出格式
# 用法: ./debug_top.sh <PID>

PID=$1

if [ -z "$PID" ]; then
    echo "用法: $0 <PID>"
    exit 1
fi

echo "=== 调试进程 $PID 的top输出 ==="
echo ""

echo "1. 完整的top输出："
echo "-------------------"
top -p $PID -n 1 -b 2>/dev/null
echo ""

echo "2. 过滤后的进程行："
echo "-------------------"
top_line=$(top -p $PID -n 1 -b 2>/dev/null | grep "^ *$PID " | head -1)
echo "原始行: '$top_line'"
echo ""

if [ -n "$top_line" ]; then
    echo "3. 字段解析："
    echo "-------------"
    echo "字段1 (PID): $(echo "$top_line" | awk '{print $1}')"
    echo "字段2 (USER): $(echo "$top_line" | awk '{print $2}')"
    echo "字段3 (PR): $(echo "$top_line" | awk '{print $3}')"
    echo "字段4 (NI): $(echo "$top_line" | awk '{print $4}')"
    echo "字段5 (VIRT): $(echo "$top_line" | awk '{print $5}')"
    echo "字段6 (RES): $(echo "$top_line" | awk '{print $6}')"
    echo "字段7 (SHR): $(echo "$top_line" | awk '{print $7}')"
    echo "字段8 (S): $(echo "$top_line" | awk '{print $8}')"
    echo "字段9 (%CPU): $(echo "$top_line" | awk '{print $9}')"
    echo "字段10 (%MEM): $(echo "$top_line" | awk '{print $10}')"
    echo "字段11 (TIME+): $(echo "$top_line" | awk '{print $11}')"
    echo "字段12+ (COMMAND): $(echo "$top_line" | awk '{for(i=12;i<=NF;i++) printf "%s ", $i; print ""}')"
    echo ""
    
    echo "4. 计算结果："
    echo "-------------"
    cpu=$(echo "$top_line" | awk '{print $9}')
    mem_percent=$(echo "$top_line" | awk '{print $10}')
    
    # 获取系统总内存
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    total_mem_mb=$((total_mem_kb / 1024))
    
    if [ -n "$mem_percent" ] && [ "$mem_percent" != "0.0" ]; then
        mem_mb=$(echo "scale=0; $total_mem_mb * $mem_percent / 100" | bc)
    else
        mem_mb="0"
    fi
    
    echo "CPU使用率: ${cpu}%"
    echo "内存百分比: ${mem_percent}%"
    echo "系统总内存: ${total_mem_mb}MB"
    echo "进程内存使用: ${mem_mb}MB"
else
    echo "错误：无法获取进程信息"
fi

echo ""
echo "5. 对比ps命令结果："
echo "-------------------"
ps_cpu=$(ps -p $PID -o %cpu --no-headers 2>/dev/null | tr -d ' ')
ps_mem_kb=$(ps -p $PID -o rss --no-headers 2>/dev/null | tr -d ' ')
ps_mem_mb=$((ps_mem_kb / 1024))

echo "PS CPU: ${ps_cpu}%"
echo "PS 内存: ${ps_mem_mb}MB (RSS)" 
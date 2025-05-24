#!/bin/bash

# 收集性能指标的脚本
# 用法: ./collect_metrics.sh <pid> <duration> <output_file>

PID=$1
DURATION=$2
OUTPUT_FILE=$3

# 创建输出文件并写入表头
echo "| 框架名 | TPS(开始) | TPS(中间) | TPS(结束) | CPU(开始) | CPU(中间) | CPU(结束) | 内存(开始) | 内存(中间) | 内存(结束) |" > "$OUTPUT_FILE"
echo "|--------|-----------|-----------|-----------|-----------|-----------|-----------|------------|------------|------------|" >> "$OUTPUT_FILE"

# 收集开始时的指标
start_cpu=$(ps -p $PID -o %cpu | tail -n 1)
start_mem=$(ps -p $PID -o %mem | tail -n 1)

# 等待一半时间后收集中间指标
sleep $((DURATION/2))
mid_cpu=$(ps -p $PID -o %cpu | tail -n 1)
mid_mem=$(ps -p $PID -o %mem | tail -n 1)

# 等待剩余时间后收集结束指标
sleep $((DURATION/2))
end_cpu=$(ps -p $PID -o %cpu | tail -n 1)
end_mem=$(ps -p $PID -o %mem | tail -n 1)

# 从benchmark输出中提取TPS数据
start_tps=$(grep "start" benchmark.log | awk '{print $2}')
mid_tps=$(grep "middle" benchmark.log | awk '{print $2}')
end_tps=$(grep "end" benchmark.log | awk '{print $2}')

# 将数据写入markdown表格
echo "| $FRAMEWORK | $start_tps | $mid_tps | $end_tps | $start_cpu | $mid_cpu | $end_cpu | $start_mem | $mid_mem | $end_mem |" >> "$OUTPUT_FILE" 
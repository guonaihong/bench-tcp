#!/bin/bash

# 添加时间戳函数
log_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# 收集性能指标的脚本
# 用法: ./collect_metrics.sh <framework> <pid> <duration> <output_file> <benchmark_pid>

FRAMEWORK=$1
PID=$2
DURATION=$3
OUTPUT_FILE=$4
BENCHMARK_PID=$5  # 新增：基准测试脚本的PID，用于文件命名

# 如果输出文件不存在，创建表头
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "| 框架名 | TPS(开始) | TPS(中间) | TPS(结束) | CPU(开始) | CPU(中间) | CPU(结束) | 内存(开始) | 内存(中间) | 内存(结束) |" > "$OUTPUT_FILE"
    echo "|--------|-----------|-----------|-----------|-----------|-----------|-----------|------------|------------|------------|" >> "$OUTPUT_FILE"
fi

log_with_timestamp "=================== Starting metrics collection for $FRAMEWORK (PID: $PID) ==================="

# 收集开始时的指标
start_cpu=$(ps -p $PID -o %cpu --no-headers | tr -d ' ')
start_mem_percent=$(ps -p $PID -o %mem --no-headers | tr -d ' ')
start_mem_kb=$(ps -p $PID -o rss --no-headers | tr -d ' ')
start_mem_mb=$((start_mem_kb / 1024))
log_with_timestamp "Start metrics collected: CPU=$start_cpu%, Memory=$start_mem_percent% ($start_mem_mb MB)"

# 等待一半时间后收集中间指标
sleep $((DURATION/2))
mid_cpu=$(ps -p $PID -o %cpu --no-headers | tr -d ' ')
mid_mem_percent=$(ps -p $PID -o %mem --no-headers | tr -d ' ')
mid_mem_kb=$(ps -p $PID -o rss --no-headers | tr -d ' ')
mid_mem_mb=$((mid_mem_kb / 1024))
log_with_timestamp "Middle metrics collected: CPU=$mid_cpu%, Memory=$mid_mem_percent% ($mid_mem_mb MB)"

# 等待剩余时间后收集结束指标
sleep $((DURATION/2))
end_cpu=$(ps -p $PID -o %cpu --no-headers | tr -d ' ')
end_mem_percent=$(ps -p $PID -o %mem --no-headers | tr -d ' ')
end_mem_kb=$(ps -p $PID -o rss --no-headers | tr -d ' ')
end_mem_mb=$((end_mem_kb / 1024))
log_with_timestamp "End metrics collected: CPU=$end_cpu%, Memory=$end_mem_percent% ($end_mem_mb MB)"

# 从对应框架的TPS文件中提取数据
TPS_FILE="$(dirname "$OUTPUT_FILE")/output/$FRAMEWORK.$BENCHMARK_PID.tps"
start_tps="N/A"
mid_tps="N/A"
end_tps="N/A"

# 等待TPS文件生成，最多重试5次
log_with_timestamp "Waiting for TPS data file: $TPS_FILE"
retry_count=0
max_retries=5

while [ $retry_count -lt $max_retries ]; do
    if [ -f "$TPS_FILE" ] && [ -s "$TPS_FILE" ]; then
        log_with_timestamp "TPS file found and not empty"
        break
    fi
    
    retry_count=$((retry_count + 1))
    log_with_timestamp "TPS file not ready, retry $retry_count/$max_retries..."
    sleep 2
done

if [ -f "$TPS_FILE" ] && [ -s "$TPS_FILE" ]; then
    start_tps=$(grep "^start" "$TPS_FILE" | awk '{print $2}' | head -1)
    mid_tps=$(grep "^middle" "$TPS_FILE" | awk '{print $2}' | head -1)
    end_tps=$(grep "^end" "$TPS_FILE" | awk '{print $2}' | head -1)
    log_with_timestamp "TPS data extracted: Start=$start_tps, Middle=$mid_tps, End=$end_tps"
else
    log_with_timestamp "Warning: TPS file not found or empty after $max_retries retries: $TPS_FILE"
    if [ -f "$TPS_FILE" ]; then
        log_with_timestamp "TPS file content: $(cat "$TPS_FILE")"
    fi
fi

# 将数据追加到markdown表格 - 修正内存单位为MB
echo "| $FRAMEWORK | $start_tps | $mid_tps | $end_tps | $start_cpu% | $mid_cpu% | $end_cpu% | ${start_mem_mb}MB | ${mid_mem_mb}MB | ${end_mem_mb}MB |" >> "$OUTPUT_FILE"

# 保存CPU和内存数据到单独文件（也使用PID后缀）
CPU_FILE="$(dirname "$OUTPUT_FILE")/output/$FRAMEWORK.$BENCHMARK_PID.cpu"
MEM_FILE="$(dirname "$OUTPUT_FILE")/output/$FRAMEWORK.$BENCHMARK_PID.mem"

echo "start $start_cpu" > "$CPU_FILE"
echo "middle $mid_cpu" >> "$CPU_FILE"
echo "end $end_cpu" >> "$CPU_FILE"

echo "start $start_mem_mb" > "$MEM_FILE"
echo "middle $mid_mem_mb" >> "$MEM_FILE"
echo "end $end_mem_mb" >> "$MEM_FILE"

log_with_timestamp "Metrics collection completed for $FRAMEWORK" 
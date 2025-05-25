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

# 初始化数组存储CPU和内存数据
cpu_values=()
mem_values=()

# 采样间隔（秒）
SAMPLE_INTERVAL=1
total_samples=$((DURATION / SAMPLE_INTERVAL))

log_with_timestamp "Will collect $total_samples samples every $SAMPLE_INTERVAL seconds for $DURATION seconds"

# 持续收集数据
for ((i=1; i<=total_samples; i++)); do
    # 使用top命令收集CPU和内存使用率
    # 检测操作系统类型以使用正确的top命令格式
    OS_TYPE=$(uname -s)
    
    if [ "$OS_TYPE" = "Darwin" ]; then
        # macOS 系统
        top_output=$(top -pid $PID -l 1 -stats pid,cpu,mem 2>/dev/null | tail -n +13 | head -1)
        if [ -n "$top_output" ]; then
            current_cpu=$(echo "$top_output" | awk '{print $2}' | sed 's/%//')
            current_mem_str=$(echo "$top_output" | awk '{print $3}')
            
            # 在macOS上，解析内存格式（如 3904K, 256M, 1.2G）
            if echo "$current_mem_str" | grep -q "K"; then
                current_mem_kb=$(echo "$current_mem_str" | sed 's/K.*//')
                current_mem_mb=$((current_mem_kb / 1024))
            elif echo "$current_mem_str" | grep -q "M"; then
                current_mem_mb=$(echo "$current_mem_str" | sed 's/M.*//' | cut -d. -f1)
            elif echo "$current_mem_str" | grep -q "G"; then
                current_mem_gb=$(echo "$current_mem_str" | sed 's/G.*//')
                current_mem_mb=$(echo "$current_mem_gb * 1024" | bc)
            else
                # 如果是纯数字，假设是KB
                current_mem_mb=$(echo "$current_mem_str / 1024" | bc 2>/dev/null || echo "0")
            fi
        else
            # 如果top命令失败，回退到ps命令
            current_cpu=$(ps -p $PID -o %cpu --no-headers 2>/dev/null | tr -d ' ')
            current_mem_kb=$(ps -p $PID -o rss --no-headers 2>/dev/null | tr -d ' ')
            current_mem_mb=$((current_mem_kb / 1024))
        fi
    else
        # Linux 系统
        # 使用更精确的top命令，确保获取正确的进程行
        top_output=$(top -p $PID -n 1 -b 2>/dev/null | grep "^ *$PID " | head -1)
        
        if [ -n "$top_output" ]; then
            # Linux top 输出格式通常是：PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND
            current_cpu=$(echo "$top_output" | awk '{print $9}')
            
            # 直接使用RES字段（实际内存使用，单位KB），更准确
            current_mem_res=$(echo "$top_output" | awk '{print $6}')
            if [ -n "$current_mem_res" ] && [ "$current_mem_res" -gt 0 ]; then
                current_mem_mb=$((current_mem_res / 1024))
            else
                current_mem_mb="0"
            fi
        else
            # 如果top命令失败，回退到ps命令
            current_cpu=$(ps -p $PID -o %cpu --no-headers 2>/dev/null | tr -d ' ')
            current_mem_kb=$(ps -p $PID -o rss --no-headers 2>/dev/null | tr -d ' ')
            current_mem_mb=$((current_mem_kb / 1024))
        fi
    fi
    
    # 检查进程是否还存在
    if [ -z "$current_cpu" ] || [ -z "$current_mem_mb" ]; then
        log_with_timestamp "Warning: Process $PID not found at sample $i, stopping collection"
        break
    fi
    
    # 确保数值有效
    if ! [[ "$current_cpu" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        current_cpu="0.0"
    fi
    if ! [[ "$current_mem_mb" =~ ^[0-9]+$ ]]; then
        current_mem_mb="0"
    fi
    
    # 存储数据
    cpu_values+=("$current_cpu")
    mem_values+=("$current_mem_mb")
    
    log_with_timestamp "Sample $i/$total_samples: CPU=${current_cpu}%, Memory=${current_mem_mb}MB (via top)"
    
    # 等待下一次采样（除了最后一次）
    if [ $i -lt $total_samples ]; then
        sleep $SAMPLE_INTERVAL
    fi
done

# 计算CPU统计值
if [ ${#cpu_values[@]} -gt 0 ]; then
    # 计算最大值
    max_cpu=${cpu_values[0]}
    for cpu in "${cpu_values[@]}"; do
        if (( $(echo "$cpu > $max_cpu" | bc -l) )); then
            max_cpu=$cpu
        fi
    done
    
    # 计算最小值
    min_cpu=${cpu_values[0]}
    for cpu in "${cpu_values[@]}"; do
        if (( $(echo "$cpu < $min_cpu" | bc -l) )); then
            min_cpu=$cpu
        fi
    done
    
    # 计算平均值
    sum_cpu=0
    for cpu in "${cpu_values[@]}"; do
        sum_cpu=$(echo "$sum_cpu + $cpu" | bc -l)
    done
    avg_cpu=$(echo "scale=1; $sum_cpu / ${#cpu_values[@]}" | bc -l)
else
    max_cpu="N/A"
    min_cpu="N/A"
    avg_cpu="N/A"
fi

# 计算内存统计值
if [ ${#mem_values[@]} -gt 0 ]; then
    # 计算最大值
    max_mem=${mem_values[0]}
    for mem in "${mem_values[@]}"; do
        if [ $mem -gt $max_mem ]; then
            max_mem=$mem
        fi
    done
    
    # 计算最小值
    min_mem=${mem_values[0]}
    for mem in "${mem_values[@]}"; do
        if [ $mem -lt $min_mem ]; then
            min_mem=$mem
        fi
    done
    
    # 计算平均值
    sum_mem=0
    for mem in "${mem_values[@]}"; do
        sum_mem=$((sum_mem + mem))
    done
    avg_mem=$((sum_mem / ${#mem_values[@]}))
else
    max_mem="N/A"
    min_mem="N/A"
    avg_mem="N/A"
fi

log_with_timestamp "CPU Statistics: Max=${max_cpu}%, Min=${min_cpu}%, Avg=${avg_cpu}%"
log_with_timestamp "Memory Statistics: Max=${max_mem}MB, Min=${min_mem}MB, Avg=${avg_mem}MB"

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

# 将数据追加到markdown表格 - 使用新的统计格式
echo "| $FRAMEWORK | $start_tps | $mid_tps | $end_tps | $max_cpu% | $min_cpu% | $avg_cpu% | ${max_mem}MB | ${min_mem}MB | ${avg_mem}MB |" >> "$OUTPUT_FILE"

# 保存CPU和内存数据到单独文件（也使用PID后缀）
CPU_FILE="$(dirname "$OUTPUT_FILE")/output/$FRAMEWORK.$BENCHMARK_PID.cpu"
MEM_FILE="$(dirname "$OUTPUT_FILE")/output/$FRAMEWORK.$BENCHMARK_PID.mem"

echo "max $max_cpu" > "$CPU_FILE"
echo "min $min_cpu" >> "$CPU_FILE"
echo "avg $avg_cpu" >> "$CPU_FILE"

echo "max $max_mem" > "$MEM_FILE"
echo "min $min_mem" >> "$MEM_FILE"
echo "avg $avg_mem" >> "$MEM_FILE"

log_with_timestamp "Metrics collection completed for $FRAMEWORK" 
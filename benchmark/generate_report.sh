#!/bin/bash

# 报表生成脚本
# Usage: generate_report.sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_FILE="$SCRIPT_DIR/benchmark_results.md"

# 创建报表文件头部
echo "# Benchmark Results" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Test completed at: $(date)" >> "$OUTPUT_FILE"
echo "Operating System: $(uname -s)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| 框架名 | TPS(开始) | TPS(中间) | TPS(结束) | CPU(开始)% | CPU(中间)% | CPU(结束)% | 内存(开始)MB | 内存(中间)MB | 内存(结束)MB |" >> "$OUTPUT_FILE"
echo "|--------|-----------|-----------|-----------|------------|------------|------------|-------------|-------------|-------------|" >> "$OUTPUT_FILE"

# 在屏幕上显示生成的报表
echo ""
echo "=========================================="
echo "Generated Report Content:"
echo "=========================================="

# 打印美化的表格到屏幕
echo "# Benchmark Results"
echo ""
echo "Test completed at: $(date)"
echo "Operating System: $(uname -s)"
echo ""

# 打印表格头部 - 使用固定宽度对齐
printf "%-6s | %-8s | %-8s | %-8s | %-7s | %-7s | %-7s | %-8s | %-8s | %-8s\n" \
    "框架" "TPS开始" "TPS中间" "TPS结束" "CPU开始" "CPU中间" "CPU结束" "内存开始" "内存中间" "内存结束"

printf "%-6s-+-%-8s-+-%-8s-+-%-8s-+-%-7s-+-%-7s-+-%-7s-+-%-8s-+-%-8s-+-%-8s\n" \
    "------" "--------" "--------" "--------" "-------" "-------" "-------" "--------" "--------" "--------"

# 处理每个框架的数据并格式化输出
for tps_file in "$SCRIPT_DIR/output"/*.tps; do
    if [ -f "$tps_file" ]; then
        # 从文件名提取框架名称
        framework=$(basename "$tps_file" .tps)
        
        # 读取TPS数据
        if [ -f "$tps_file" ]; then
            start_tps=$(grep "^start" "$tps_file" | awk '{print $2}' || echo "N/A")
            middle_tps=$(grep "^middle" "$tps_file" | awk '{print $2}' || echo "N/A")
            end_tps=$(grep "^end" "$tps_file" | awk '{print $2}' || echo "N/A")
        else
            start_tps="N/A"
            middle_tps="N/A"
            end_tps="N/A"
        fi
        
        # 读取CPU数据
        cpu_file="$SCRIPT_DIR/output/$framework.cpu"
        if [ -f "$cpu_file" ]; then
            start_cpu=$(grep "^start" "$cpu_file" | awk '{print $2}' || echo "N/A")
            middle_cpu=$(grep "^middle" "$cpu_file" | awk '{print $2}' || echo "N/A")
            end_cpu=$(grep "^end" "$cpu_file" | awk '{print $2}' || echo "N/A")
        else
            start_cpu="N/A"
            middle_cpu="N/A"
            end_cpu="N/A"
        fi
        
        # 读取内存数据
        mem_file="$SCRIPT_DIR/output/$framework.mem"
        if [ -f "$mem_file" ]; then
            start_mem=$(grep "^start" "$mem_file" | awk '{print $2}' || echo "N/A")
            middle_mem=$(grep "^middle" "$mem_file" | awk '{print $2}' || echo "N/A")
            end_mem=$(grep "^end" "$mem_file" | awk '{print $2}' || echo "N/A")
        else
            start_mem="N/A"
            middle_mem="N/A"
            end_mem="N/A"
        fi
        
        # 格式化打印到屏幕
        printf "%-6s | %-8s | %-8s | %-8s | %-7s | %-7s | %-7s | %-8s | %-8s | %-8s\n" \
            "$framework" "$start_tps" "$middle_tps" "$end_tps" \
            "${start_cpu}%" "${middle_cpu}%" "${end_cpu}%" \
            "${start_mem}MB" "${middle_mem}MB" "${end_mem}MB"
        
        # 写入到文件（保持原格式）
        echo "| $framework | $start_tps | $middle_tps | $end_tps | $start_cpu% | $middle_cpu% | $end_cpu% | ${start_mem}MB | ${middle_mem}MB | ${end_mem}MB |" >> "$OUTPUT_FILE"
    fi
done

echo ""
echo "=========================================="

echo "" >> "$OUTPUT_FILE"
echo "Report generated successfully at: $OUTPUT_FILE" 
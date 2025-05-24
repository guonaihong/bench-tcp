#!/bin/bash

# This is a core benchmark script that can be called with different parameters
# Usage: benchmark-core.sh [concurrency] [duration] [extra_args]
# Example: benchmark-core.sh 10000 100s

# Default values
CONCURRENCY=${1:-10000}  # Default to 10k connections if not specified
DURATION=${2:-100s}      # Default to 100 seconds if not specified
EXTRA_ARGS=${3:-""}      # Additional arguments to pass to bench-tcp

# Stop any existing servers first
echo "Stopping any existing servers..."
"$(dirname "$0")/stop-servers.sh"

# Source the config file to get ENABLED_SERVERS
source "$(dirname "$0")/config.sh"

# Export port ranges as environment variables for lib servers
for server in "${ENABLED_SERVERS[@]}"; do
    # Convert server name to uppercase and replace - with _
    server_upper=$(echo "$server" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    start_var="${server_upper}_START_PORT"
    end_var="${server_upper}_END_PORT"
    
    # Export port ranges to environment variables
    export "$server_upper"_START_PORT="${!start_var}"
    export "$server_upper"_END_PORT="${!end_var}"
    echo "Exported $server_upper port range: ${!start_var}-${!end_var}"
done

# Start all enabled servers
echo "Starting servers..."
"$(dirname "$0")/start-servers.sh"

# Wait a bit for servers to be ready
sleep 2

# Detect OS type to use correct binary
OSTYPE=$(uname -s)
if [[ "$OSTYPE" == "Linux" ]]; then
    BENCH_BIN="bin/bench-tcp.linux"
elif [[ "$OSTYPE" == "Darwin" ]]; then
    BENCH_BIN="bin/bench-tcp.mac"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

echo "Running benchmarks with concurrency: $CONCURRENCY, duration: $DURATION"

# Run benchmarks for each enabled server
echo "Running benchmarks..."
for server in "${ENABLED_SERVERS[@]}"; do
    echo "Benchmarking $server..."
    
    # Convert server name to uppercase and replace - with _
    server_upper=$(echo "$server" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    start_var="${server_upper}_START_PORT"
    end_var="${server_upper}_END_PORT"
    
    # Run bench-tcp with port range
    echo "Testing $server on port range ${!start_var}-${!end_var}..."
    
    if [ ! -x "$BENCH_BIN" ]; then
        echo "Error: Benchmark executable not found or not executable: $BENCH_BIN"
        exit 1
    fi
    
    # Run the benchmark with specified parameters
    "$BENCH_BIN" -d "$DURATION" -c "$CONCURRENCY" --addr "127.0.0.1:${!start_var}-${!end_var}" --open-tmp-result $EXTRA_ARGS
done

# Stop all servers
echo "Stopping servers..."
"$(dirname "$0")/stop-servers.sh"

echo "Benchmark complete!"

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 设置基准测试参数
DURATION=60  # 测试持续时间（秒）
OUTPUT_FILE="$SCRIPT_DIR/benchmark_results.md"

# 创建必要的目录
mkdir -p "$SCRIPT_DIR/output"

# 创建或清空结果文件
echo "# Benchmark Results" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 启动性能数据收集
start_metrics_collection() {
    local server=$1
    local pid=$2
    local duration=$3
    local output_file=$4
    
    # 启动性能数据收集
    "$SCRIPT_DIR/collect_metrics.sh" $pid $duration "$output_file" &
    COLLECTOR_PID=$!
    echo $COLLECTOR_PID
}

# 运行基准测试
run_benchmark() {
    local server=$1
    local duration=$2
    
    echo "Running benchmark for $server..."
    # 运行bench-tcp客户端并将输出重定向到对应的.tps文件
    "$SCRIPT_DIR/bench-tcp" --duration $duration > "$SCRIPT_DIR/output/$server.tps"
}

# 停止测试
stop_test() {
    local collector_pid=$1
    local server_pid=$2
    
    # 停止性能数据收集
    if [ -n "$collector_pid" ]; then
        kill $collector_pid 2>/dev/null || true
    fi
    
    # 停止服务器
    if [ -n "$server_pid" ]; then
        kill $server_pid 2>/dev/null || true
    fi
    
    # 等待进程完全停止
    if [ -n "$server_pid" ]; then
        wait $server_pid 2>/dev/null || true
    fi
    if [ -n "$collector_pid" ]; then
        wait $collector_pid 2>/dev/null || true
    fi
}

# 处理单个服务器的测试
test_server() {
    local server=$1
    local duration=$2
    local output_file=$3
    
    echo "Testing $server..."
    
    # 启动服务器
    cd "$SCRIPT_DIR/../lib/$server"
    if [ ! -f "./$server" ]; then
        echo "Error: Server executable not found: $server"
        return 1
    fi
    
    ./$server &
    SERVER_PID=$!
    cd "$SCRIPT_DIR"
    
    # 等待服务器启动
    sleep 2
    
    # 启动性能数据收集
    COLLECTOR_PID=$(start_metrics_collection "$server" $SERVER_PID $duration "$output_file")
    
    # 运行基准测试
    run_benchmark "$server" $duration
    
    # 等待基准测试完成
    sleep $duration
    
    # 停止测试
    stop_test $COLLECTOR_PID $SERVER_PID
    
    echo "Completed testing $server"
    echo "" >> "$output_file"
    
    # 在测试下一个框架之前等待3秒
    echo "Waiting 3 seconds before testing next framework..."
    sleep 3
}

# 处理所有服务器的测试
run_all_tests() {
    local servers=("$@")
    local duration=$DURATION
    local output_file=$OUTPUT_FILE
    
    for server in "${servers[@]}"; do
        test_server "$server" $duration "$output_file"
    done
    
    # 运行benchmark.go处理所有收集到的数据
    cd "$SCRIPT_DIR"
    go run benchmark.go
}

# 如果直接运行此脚本，则执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 加载配置
    if [ ! -f "$SCRIPT_DIR/config.sh" ]; then
        echo "Error: config.sh not found in $SCRIPT_DIR"
        exit 1
    fi
    source "$SCRIPT_DIR/config.sh"
    run_all_tests "${ENABLED_SERVERS[@]}"
    echo "Benchmark completed. Results saved to $OUTPUT_FILE"
fi 
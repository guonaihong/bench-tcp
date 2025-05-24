package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/guonaihong/clop"
)

// Options 命令行参数
type Options struct {
	Duration int    `clop:"duration;default=60" usage:"Duration of the benchmark in seconds"`
	Output   string `clop:"output;default=benchmark.log" usage:"Output file for benchmark results"`
}

// TPSData 存储TPS数据
type TPSData struct {
	Start  int
	Middle int
	End    int
}

// readTPSData 从指定文件读取TPS数据
func readTPSData(framework string) (*TPSData, error) {
	filePath := filepath.Join("output", framework+".tps")
	file, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open TPS file: %v", err)
	}
	defer file.Close()

	data := &TPSData{}
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.Split(line, " ")
		if len(parts) != 2 {
			continue
		}

		value, err := strconv.Atoi(parts[1])
		if err != nil {
			continue
		}

		switch parts[0] {
		case "start":
			data.Start = value
		case "middle":
			data.Middle = value
		case "end":
			data.End = value
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("error reading TPS file: %v", err)
	}

	return data, nil
}

func main() {
	var opt Options
	err := clop.Bind(&opt)
	if err != nil {
		log.Fatalf("Failed to parse command line options: %v", err)
	}

	// 创建输出文件
	f, err := os.Create(opt.Output)
	if err != nil {
		log.Fatalf("Failed to create output file: %v", err)
	}
	defer f.Close()

	// 记录开始时间
	startTime := time.Now()

	// 从output目录读取所有.tps文件
	files, err := filepath.Glob("output/*.tps")
	if err != nil {
		log.Fatalf("Failed to read TPS files: %v", err)
	}

	// 处理每个框架的TPS数据
	for _, file := range files {
		framework := strings.TrimSuffix(filepath.Base(file), ".tps")
		tpsData, err := readTPSData(framework)
		if err != nil {
			log.Printf("Warning: Failed to read TPS data for %s: %v", framework, err)
			continue
		}

		// 写入TPS数据到输出文件
		fmt.Fprintf(f, "start %d\n", tpsData.Start)
		fmt.Fprintf(f, "middle %d\n", tpsData.Middle)
		fmt.Fprintf(f, "end %d\n", tpsData.End)
	}

	// 记录总时间
	totalTime := time.Since(startTime)
	fmt.Fprintf(f, "Total time: %v\n", totalTime)
}

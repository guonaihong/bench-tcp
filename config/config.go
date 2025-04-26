package config

import (
	"fmt"
	"strings"
)

// 需要满足的写法如下
// host:port
// host:minport-maxport
func GenerateAddrs(addr, name string) []string {
	if addr == "" {
		return nil
	}

	// 查找冒号的位置
	colonPos := strings.Index(addr, ":")

	// 如果没有找到冒号，直接返回原地址
	if colonPos == -1 {
		return []string{addr}
	}

	host := addr[:colonPos]
	portStr := addr[colonPos+1:]

	// 查找端口范围中的连字符
	hyphenPos := strings.Index(portStr, "-")

	// 如果没有连字符，说明是单一端口
	if hyphenPos == -1 {
		return []string{addr}
	}

	// 解析端口范围
	minPortStr := portStr[:hyphenPos]
	maxPortStr := portStr[hyphenPos+1:]

	var minPort, maxPort int
	_, err := fmt.Sscanf(minPortStr, "%d", &minPort)
	if err != nil {
		return []string{addr}
	}

	_, err = fmt.Sscanf(maxPortStr, "%d", &maxPort)
	if err != nil {
		return []string{addr}
	}

	// 如果最小端口大于最大端口，交换它们
	if minPort > maxPort {
		minPort, maxPort = maxPort, minPort
	}

	// 生成所有地址
	addrs := make([]string, 0, maxPort-minPort+1)
	for port := minPort; port <= maxPort; port++ {
		addrs = append(addrs, fmt.Sprintf("%s:%d", host, port))
	}

	return addrs
}

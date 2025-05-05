package port

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

// PortRange represents a range of ports
type PortRange struct {
	Start int
	End   int
}

// GetPortRange returns the port range for a given library name
func GetPortRange(libName string) (*PortRange, error) {
	startPort := os.Getenv(fmt.Sprintf("%s_START_PORT", strings.ToUpper(libName)))
	endPort := os.Getenv(fmt.Sprintf("%s_END_PORT", strings.ToUpper(libName)))

	if startPort == "" || endPort == "" {
		return nil, fmt.Errorf("port range not configured for library %s", libName)
	}

	start, err := strconv.Atoi(startPort)
	if err != nil {
		return nil, fmt.Errorf("invalid start port for %s: %v", libName, err)
	}

	end, err := strconv.Atoi(endPort)
	if err != nil {
		return nil, fmt.Errorf("invalid end port for %s: %v", libName, err)
	}

	return &PortRange{
		Start: start,
		End:   end,
	}, nil
}

// GetNextPort returns the next available port in the range
func (pr *PortRange) GetNextPort(current int) int {
	if current < pr.Start || current >= pr.End {
		return pr.Start
	}
	return current + 1
}

// Format returns the port range as a string
func (pr *PortRange) Format() string {
	return fmt.Sprintf("%d-%d", pr.Start, pr.End)
}

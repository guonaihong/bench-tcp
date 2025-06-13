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

// Default port ranges for different libraries
var defaultPortRanges = map[string]PortRange{
	"NET_TCP":  {Start: 1000, End: 1000},
	"UIO":      {Start: 1100, End: 1100},
	"EVIO":     {Start: 1200, End: 1200},
	"NETPOLL":  {Start: 1300, End: 1300},
	"GNET":     {Start: 1400, End: 1400},
	"GEV":      {Start: 1500, End: 1500},
	"NBIO":     {Start: 1600, End: 1600},
	"PULSE":    {Start: 1700, End: 1700},
	"PULSE_ET": {Start: 1800, End: 1800},
}

// GetPortRange returns the port range for a given library name
func GetPortRange(libName string) (*PortRange, error) {
	libName = strings.ToUpper(libName)
	startPort := os.Getenv(fmt.Sprintf("%s_START_PORT", libName))
	endPort := os.Getenv(fmt.Sprintf("%s_END_PORT", libName))

	// If environment variables are not set, use default values
	if startPort == "" || endPort == "" {
		if defaultRange, ok := defaultPortRanges[libName]; ok {
			return &defaultRange, nil
		}
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

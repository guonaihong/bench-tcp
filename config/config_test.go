package config

import (
	"reflect"
	"sort"
	"testing"
)

func TestGenerateAddrs(t *testing.T) {
	tests := []struct {
		name     string
		addr     string
		servName string
		want     []string
	}{
		{
			name:     "empty address",
			addr:     "",
			servName: "test",
			want:     nil,
		},
		{
			name:     "no colon in address",
			addr:     "localhost",
			servName: "test",
			want:     []string{"localhost"},
		},
		{
			name:     "single port",
			addr:     "localhost:8080",
			servName: "test",
			want:     []string{"localhost:8080"},
		},
		{
			name:     "port range",
			addr:     "localhost:8080-8082",
			servName: "test",
			want:     []string{"localhost:8080", "localhost:8081", "localhost:8082"},
		},
		{
			name:     "reversed port range",
			addr:     "localhost:8082-8080",
			servName: "test",
			want:     []string{"localhost:8080", "localhost:8081", "localhost:8082"},
		},
		{
			name:     "invalid min port",
			addr:     "localhost:abc-8080",
			servName: "test",
			want:     []string{"localhost:abc-8080"},
		},
		{
			name:     "invalid max port",
			addr:     "localhost:8080-xyz",
			servName: "test",
			want:     []string{"localhost:8080-xyz"},
		},
		{
			name:     "IP address with port range",
			addr:     "127.0.0.1:9000-9002",
			servName: "test",
			want:     []string{"127.0.0.1:9000", "127.0.0.1:9001", "127.0.0.1:9002"},
		},
	}

	for _, tt := range tests {
		tt := tt // capture range variable
		t.Run(tt.name, func(t *testing.T) {
			got := GenerateAddrs(tt.addr, tt.servName)
			
			// Sort both slices to ensure consistent comparison
			if got != nil {
				sort.Strings(got)
			}
			if tt.want != nil {
				sort.Strings(tt.want)
			}
			
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("GenerateAddrs() = %v, want %v", got, tt.want)
			}
		})
	}
}

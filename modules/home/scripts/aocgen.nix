{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: let

  isLinux = pkgs.stdenv.isLinux;
  aocgen = pkgs.writeShellScriptBin "aocgen" ''
#!/bin/bash

# Check if a project name was provided
if [ -z "$1" ]; then
	echo "Error: missing directory name"
	exit 1
fi

# Check if a module name was provided
if [ -z "$2" ]; then
	echo "Error: missing module name"
	exit 1
fi

# Create a new directory for the project
mkdir "$1"

# Create main.go and add a main function that prints "hello world"
cat >"$1/main.go" <<EOF
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
  fmt.Println("hello world")
}

func run(filename string) int {
	input, _ := os.Open(filename)
	defer input.Close()
	sc := bufio.NewScanner(input)

	for sc.Scan() {
    fmt.Println(sc.Text())
  }
  return 0
}
EOF

# Create main_test.go
cat >"$1/main_test.go" <<EOF
package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_Run(t *testing.T) {
	cases := []struct {
		name     string
		actual   string
		expected int
	}{
		{
			name:     "example",
			actual:   "example.input",
			expected: 13,
		},
		{
			name:     "large example",
			actual:   "large.input",
			expected: 6175,
		},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got := run(c.actual)
			assert.Equal(t, c.expected, got)
		})
	}
}
EOF

cat >"$1/example.input" <<EOF
1 2 3
4 5 6
EOF

cat >"$1/large.input" <<EOF
1 2 3
4 5 6
7 8 9
EOF

# Initialize go mod with the provided project name
cd "$1"
go mod init "$2"

# Install the testify package for testing
go get github.com/stretchr/testify/require

''
in {
  home.packages =
  [
    aocgen
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}

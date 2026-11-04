package main

import (
	"fmt"
	"os"

	"github.com/DevonPeroutky/dotfiles/internal/cli"
)

var version = "dev"

func main() {
	if err := cli.New(version).Execute(); err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
}

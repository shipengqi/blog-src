package cmd

import (
	"os"
	"strings"

	"github.com/spf13/cobra"
)


func NewRootCommand(version string) *cobra.Command {
	rootCmd := &cobra.Command{
		Use:	"blogManager",
		Short:	"Run the blog dev server and deploy blog source code on GitHub Pages.",
		Version: version,
		PreRun: func(cmd *cobra.Command, args []string) {
			if len(args) > 0 && !strings.HasPrefix(args[0], "-") {
				cmd.Help()
				os.Exit(0)
			}
		},
		Run: func(cmd *cobra.Command, args []string) {
			cmd.Help()
		},
	}

	rootCmd.ResetFlags()
	rootCmd.AddCommand(deployCommand())
	rootCmd.AddCommand(startCommand())

	return rootCmd
}

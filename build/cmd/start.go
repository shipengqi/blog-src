package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
	"os"

	"blog-build/pkg/command"
)


type startConfig struct {
	port	int
}

func startCommand() *cobra.Command {
	cfg := &startConfig{}

	cmd := &cobra.Command{
		Use:	"start",
		Short:	"Start the blog dev server.",
		Run: func(cmd *cobra.Command, args []string) {
			err := command.ExecSync("hexo", "s", fmt.Sprintf("-p %d", cfg.port))
			if err != nil {
				fmt.Printf("Start blog dev server failed: %s.\n", err)
				os.Exit(1)
			}
		},
	}

	addStartFlags(cmd.PersistentFlags(), cfg)

	return cmd
}

func addStartFlags(flagSet *pflag.FlagSet, cfg *startConfig) {
	flagSet.IntVarP(&cfg.port, "port", "P", 8081, "Specify the port of the dev server.")
}
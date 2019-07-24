package cmd

import (
	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
)


type deployConfig struct {
	proxy		string
	theme		string
}

func deployCommand() *cobra.Command {
	cfg := &deployConfig{}

	cmd := &cobra.Command{
		Use:	"deploy",
		Short:	"Deploy the blog source code on GitHub Pages.",
		Run: func(cmd *cobra.Command, args []string) {

		},
	}

	addDeployFlags(cmd.PersistentFlags(), cfg)

	return cmd
}

func addDeployFlags(flagSet *pflag.FlagSet, cfg *deployConfig) {
	flagSet.StringVarP(&cfg.proxy, "proxy", "p", "", "Specify the http proxy.")
	flagSet.StringVarP(&cfg.theme, "theme", "t", "", "Specify the theme of the blog.")
}
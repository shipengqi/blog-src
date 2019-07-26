package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/pflag"

	"blog-build/pkg/command"
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
		PreRun: func(cmd *cobra.Command, args []string) {
			if cfg.proxy != "" {
				os.Setenv("http_proxy", cfg.proxy)
				os.Setenv("https_proxy", cfg.proxy)
				os.Setenv("HTTP_PROXY", cfg.proxy)
				os.Setenv("HTTPS_PROXY", cfg.proxy)
				os.Setenv("no_proxy", "127.0.0.1,localhost,.hpe.com,.hp.com,.hpeswlab.net")
				os.Setenv("NO_PROXY", os.Getenv("no_proxy"))
			}
		},
		Run: func(cmd *cobra.Command, args []string) {
			if cfg.theme == "cactus" {
				err := command.ExecSync("hexo", "clean")
				if err != nil {
					fmt.Printf("Clean theme: %s static files failed: %s.\n", cfg.theme, err)
					os.Exit(1)
				}
				err = command.ExecSync("hexo", "d")
				if err != nil {
					fmt.Printf("Deploy blog theme: %s failed: %s.\n", cfg.theme, err)
					os.Exit(1)
				}
			} else if cfg.theme == "next" {
				os.Setenv("HEXO_ALGOLIA_INDEXING_KEY", "fff267b07b3a0db8d496a17fe3601667")
				err := command.ExecSync("hexo", "clean")
				if err != nil {
					fmt.Printf("Clean theme: %s static files failed: %s.\n", cfg.theme, err)
					os.Exit(1)
				}
				err = command.ExecSync("hexo", "algolia")
				if err != nil {
					fmt.Printf("Configure algolia search failed: %s.\n", err)
					os.Exit(1)
				}
				err = command.ExecSync("hexo", "d")
				if err != nil {
					fmt.Printf("Deploy blog theme: %s failed: %s.\n", cfg.theme, err)
					os.Exit(1)
				}
			} else {
				fmt.Println("Unsupported theme.")
			}
		},
	}

	addDeployFlags(cmd.PersistentFlags(), cfg)

	return cmd
}

func addDeployFlags(flagSet *pflag.FlagSet, cfg *deployConfig) {
	flagSet.StringVarP(&cfg.proxy, "proxy", "p", "http://web-proxy.cn.softwaregrp.net:8080", "Specify the http proxy.")
	flagSet.StringVarP(&cfg.theme, "theme", "t", "cactus", "Specify the theme of the blog.")
}
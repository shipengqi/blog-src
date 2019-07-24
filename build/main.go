package main

import (
	"blog-build/cmd"
	"encoding/json"
	"io/ioutil"
)

type PackageJson struct {
	Version string `json:"version"`
}



func main() {
	packageJson := PackageJson{}
	packageJson.ReadVersion("../package.json", &packageJson)
	rootCmd := cmd.NewRootCommand(packageJson.Version)
	rootCmd.Execute()
}


func (pj *PackageJson) ReadVersion(filename string, v *PackageJson) {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return
	}

	err = json.Unmarshal(data, v)
	if err != nil {
		return
	}
}
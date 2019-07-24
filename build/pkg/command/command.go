package command

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"os/exec"
)

func Exec(command string) (string, string, error) {
	cmd := exec.Command("/bin/sh", "-c", command)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		return "", "", err
	}
	return string(stdout.Bytes()), string(stderr.Bytes()), nil
}

func ExecSync(command string) error {
	cmd := exec.Command("/bin/sh", "-c", command)
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	cmd.Start()
	reader := bufio.NewReader(stdout)
	for {
		line, err2 := reader.ReadString('\n')
		if err2 != nil || io.EOF == err2 {
			break
		}
		fmt.Print(line)
	}
	err = cmd.Wait()
	if err != nil {
		return err
	}
	return nil
}
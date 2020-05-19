package main

import (
	"fmt"
	"runtime"
)

func g2() {
	sum := 0
	for {
		sum++
		fmt.Println("g2 scheduled!", sum)
	}
}

func main() {
	go g2()

	for {
		runtime.Gosched()
		fmt.Println("main is scheduled!")
	}
}
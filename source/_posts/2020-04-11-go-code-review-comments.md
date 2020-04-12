---
title: Go Code Review Comments（翻译）
date: 2020-04-11 13:54:13
categories: ["Go"]
---

本页收集了在 review go 代码时常见的评论。这只是一份常见错误的清单，并不是一个全面的风格指南。全面的风格指南可以参考 [The Uber Go Style Guide](https://github.com/uber-go/guide)。

可以看做是对 [Effective Go](https://golang.org/doc/effective_go.html) 的补充。

## Gofmt
所有代码在发布前均使用 `gofmt` 进行修正。

另一种方法是使用 [goimports](https://godoc.org/golang.org/x/tools/cmd/goimports)，这是 `gofmt` 的一个超集，可以根据需要添
加（和删除）导入行。

## Comment Sentences
[commentary](https://golang.org/doc/effective_go.html#commentary) 注释应该是完整的句子，即使这似乎有点多余。这样做，能使注释在
转化成 `godoc` 时有一个不错的格式。注释应该以要描述的对象开头，句号结尾。

```go
// Request represents a request to run a command.
type Request struct { ...

// Encode writes the JSON encoding of req to w.
func Encode(w io.Writer, req *Request) { ...
```

## Contexts
`context.Context` 类型的值（可以是安全凭证、跟踪信息、截止日期和取消信号）可以跨越 API 和进程边界。Go 程序在整个函数调用链中显
式地将 Contexts 从传入的 RPC 和 HTTP 请求传递到传出的请求。

Context 所多数作为函数的第一个参数:
```go
func F(ctx context.Context, /* other arguments */) {}
```

不特定于请求的函数可能会使用 `context.background()`，即使你认为不需要这样做，也最好传递一个上下文。默认的情况是传递一
个 Context；当有充分的理由可以替代的情况下，才会直接使用 `context.Background()`。

不要在结构类型中添加 Context 成员，而是在该类型上的每个需要传递的方法中添加一个 ctx 参数。唯一的例外方法，就是签名必须与标准库或第三
方库中的接口相匹配时。

不要创建自定义的 Context 类型，或者在函数签名中使用 Context 以外的接口。

如果需要传递应用数据，就把它放在参数中，在接收器中，globals 的，或者，如果它真的属于那里，就放在 Context 的值中。

Contexts 是不可更改的，所以将 ctx 传递给多个调用可以共享相同的 deadline, cancellation signal, credentials, parent trace 等。

## Crypto Rand
不要使用 `math/rand` 包来生成密钥，即使是一次性密钥。应该使用 `crypto/rand`：
```go
import (
	"crypto/rand"
	// "encoding/base64"
	// "encoding/hex"
	"fmt"
)

func Key() string {
	buf := make([]byte, 16)
	_, err := rand.Read(buf)
	if err != nil {
		panic(err)  // out of randomness, should never happen
	}
	return fmt.Sprintf("%x", buf)
	// or hex.EncodeToString(buf)
	// or base64.StdEncoding.EncodeToString(buf)
}
```
## Declaring Empty Slices

声明空的 slice，最好使用

```go
var t []string
```

不要使用：

```go
t := []string{}
```

前者声明了一个值为 nil 的 slice，有些时候，而后者声明了一个长度为 0 的 non-nil slice。两者使用 `len` 和 `cap` 得到的都是零，但是
应该优先使用前者。因为可能你从没向这个 slice append 元素，使用前者，可以避免内存分配。

注意，在有些情况下，non-nil slice 是首选的，比如对 JSON 对象进行编码时（nil slice 编码为 null，而 `[]string{}` 编码为 JSON 数
组 `[]`）。

在设计接口时，要避免区分 nil slice 和 non-nil slice、"零长度" 切片，因为这可能会导致微妙的编程错误。

## Doc Comments
所有顶级的、导出的名称都应该有 doc 注释，不重要的未导出的 `type` 或 `func` 声明也应该有 doc 注释。
有关注释的更多信息，可以参考 [commentary](https://golang.org/doc/effective_go.html#commentary)

Go 提供两种注释风格，C 的块注释风格 `/**/`，C++ 的行注释风格 `//`。块注释主要作为包的注释，但在表达式中或禁用大段代码时也很有用。

每一个包都应该有包注释，位于文件的顶部，在包名出现之前。如果一个包有多个文件，包注释只需要出现在一个文件的顶部即可。
包注释应该介绍包，并提供与整个包相关的信息。它将首先出现在 `godoc` 页面上，并应设置下面的详细文档。

包注释建议使用块注释风格，如果这个包特别简单，需要的注释很少，也可以选择使用行注释。

## Don’t Panic
[errors](https://golang.org/doc/effective_go.html#errors) 尽量不要使用 panic 处理一般的错误。函数应该设计成多返回值，其中包括
要返回的 error 类型。

## Error Strings
错误字符串不应该大写（除非以专有名词或缩略语开头），也不应该以标点符号结尾，因为它们通常是在其他上下文之后打印的。也就是说，使
用 `fmt.Errorf("something bad")` 而不是 `fmt.Errorf("Something bad")`，这样 `log.Printf("Reading %s: %v", filename, err)`
的格式化就不会在消息中间出现一个大写字母。

这不适用于日志记录，它是隐式的、面向行的，并且不与其他消息结合在一起。

## Examples
当添加一个新的包时，要包含使用示例：一个可运行的例子，或一个简单的测试，演示一个完整的调用。

更多参考 [testable Example() functions](https://blog.golang.org/examples)。

## Goroutine Lifetimes

## Handle Errors
[errors](https://golang.org/doc/effective_go.html#errors) 不要将 error 赋值给匿名变量 `_`。如果一个函数返回 error，一定要检
查它是否为空，判断函数调用是否成功。如果不为空，就需要处理这个错误，或者 return 给调用者，特殊情况下可以 panic。

## Imports
除非导入之间有直接冲突，否则应避免导入别名。
导入烦人包应该进行分组。同一组的包之间不需要有空行，不同组之间的包需要一个空行。标准库的包应该放在第一组。

`goimports` 可以直接修正 import 包的规范。

```go
package main

import (
	"fmt"
	"hash/adler32"
	"os"

	"appengine/foo"
	"appengine/user"

	"github.com/foo/bar"
	"rsc.io/goversion/version"
)
```
## Import Blank
只为其副作用而导入的包（使用语法 `import _ "pkg"`）只应在程序的 `main` 包中，或在需要它们的测试中导入。

## Import Dot
在那些由于循环依赖关系而不能成为被测包的一部分的测试中，使用 `import . "pkg"`。

```go
package foo_test

import (
	"bar/testutil" // also imports "foo"
	. "foo"
)
```

上面的例子，该测试文件不能定义在于 `foo` 包里面，因为它导入了 `bar/testutil`，而 `bar/testutil` import 了 `foo`，这会造成循环
引用。

所以需要将该测试文件定义在 `foo_test` 包中。使用了 `import . "foo"` 后，该测试文件内代码能直接调用 `foo` 里面的函数而不需要显式
地写上包名。

但 `import .` 这个特性，建议只在这种场景下使用，因为它会影响代码的可读性。

## In-Band Errors
在 C 语言和类似的语言中，通常函数会返回像 `-1` 或 `null` 来表示错误或结果丢失:
```go
// Lookup returns the value for key or "" if there is no mapping for key.
func Lookup(key string) string

// Failing to check a for an in-band error value can lead to bugs:
Parse(Lookup(key))  // returns "parse failure for value" instead of "no value for key"
```

Go 提供了更好的结局方案，就是支持返回多个值。一个函数应该返回一个额外的值来表示它的其他返回值是否有效。这个返回值可以是一个 error，也
可以是一个布尔值。

```go
// Lookup returns the value for key or ok=false if there is no mapping for key.
func Lookup(key string) (value string, ok bool)
```

这样可以防止调用者错误地使用结果：
```go
Parse(Lookup(key))  // compile-time error
```

并鼓励更健壮，可读性更好的代码:
```go
value, ok := Lookup(key)
if !ok {
	return fmt.Errorf("no value for %q", key)
}
return Parse(value)
```
## Indent Error Flow
优先处理 error，尽可能减少正常逻辑代码的缩进，这有利于提高代码的可读性，便于快速分辨出哪些还是正常逻辑代码，

bad：
```go
if err != nil {
    // error handling
} else {
    // normal code
}
```

good：
```go
if err != nil {
    // error handling
    return // or continue, etc.
}
// normal code
```

另一种常见的情况，如果我们需要用函数的返回值来初始化某个变量，应该把这个函数调用单独写在一行，例如：

这是一个不好的代码风格，函数调用，初始化变量x，判断错误是否为空都在同一行，并增加了正常逻辑代码的缩进：

如果 `if` 语句有一个初始化语句，例如：
```go
if x, err := f(); err != nil {
    // error handling
    return
} else {
    // use x
}
```

应该把函数调用写在单独的一行：
```go
x, err := f()
if err != nil {
    // error handling
    return
}
// use x
```

## Initialisms
单词的命名，如果是首字母缩写或缩略语的词（如 "URL "或 "NATO"）的，那么大小写要一致。例如，"URL "应该作为 "URL "或 "url"
（如 "urlPony"，或 "URLPony"），而不是 "Url"。例如，`ServeHTTP` 而不是 `ServeHttp`。

这条规则同样适用于 "ID"，当它是 identifier 的缩写的时候，所以应该是 "appID" 而不是 "appId"。

## Interfaces

Go 的接口一般属于使用这个接口类型的包，而不是实现这个接口的包。实现包返回具体的（通常是指针或结构）类型：这样，可以在不需要大量重构
的情况下添加新的方法。

不要为了 "mock" 在实现包定义接口，设计的 API 应该可以使用 public API 来测试。

在使用接口之前，不要定义接口：如果没有一个实际的使用示例，很难看出接口是否有必要，更不用说接口应该包含哪些方法了。

```go
package consumer  // consumer.go

type Thinger interface { Thing() bool }

func Foo(t Thinger) string { … }
```

```go
package consumer // consumer_test.go

type fakeThinger struct{ … }
func (t fakeThinger) Thing() bool { … }
…
if Foo(fakeThinger{…}) == "x" { … }
```

```go
// DO NOT DO IT!!!
package producer

type Thinger interface { Thing() bool }

type defaultThinger struct{ … }
func (t defaultThinger) Thing() bool { … }

func NewThinger() Thinger { return defaultThinger{ … } }
```

相反，应该返回一个具体的类型，让 consumer 模拟 producer 实现。

```go
package producer

type Thinger struct{ … }
func (t Thinger) Thing() bool { … }

func NewThinger() Thinger { return Thinger{ … } }
```

## Line Length
在 Golang 中，没有严格限制代码行长度，但是应该尽量避免一行内写过长的代码，以及将长代码进行断行。

## Mixed Caps
[mixed-caps](https://golang.org/doc/effective_go.html#mixed-caps) Go 建议使用驼峰式命名，不建议使用下划线命名。


## Named Result Parameters
如果给返回值参数命名，例如：
```go
func (n *Node) Parent1() (node *Node) {}
func (n *Node) Parent2() (node *Node, err error) {}
```

但是会影响 godoc，建议使用：
```go
func (n *Node) Parent1() *Node {}
func (n *Node) Parent2() (*Node, error) {}
```

另一方面，如果一个函数返回两个或三个相同类型的参数，或者如果一个返回结果的含义从上下文中看不清楚，这个时候就可以给返回值参数命名。

不要为了避免在函数中声明一个变量而给返回值参数命名；这样做是以牺牲不必要的 API 的冗长性为代价，换取了一个小的实现简洁性。

```go
func (f *Foo) Location() (float64, float64, error)
```

上面的代码没有下面的示例可读性好：

```go
// Location returns f's latitude and longitude.
// Negative values mean south and west, respectively.
func (f *Foo) Location() (lat, long float64, err error)
```
doc 的清晰度永远比在你的功能中保存一两行更重要。

最后，在某些情况下，当你需要在 `defer` 函数中对返回值做一些事情的时候，给返回值命名是有必要的。

## Package Comments
与 godoc 提供的所有注释一样，包注释必须紧挨着 `package` 子句，不能出现空行。
```go
// Package math provides basic constants and mathematical functions.
package math
```

```go
/*
Package template implements data-driven templates for generating textual
output such as HTML.
....
*/
package template
```

对于 `package main` 的注释，注释可以放在二进制名之后(如果在前面，可以大写)，例如，对于 `seedgen` 目录中的一
个 `package main`，可以这样写:
```go
// Binary seedgen ...
package main
```
或者
```go
// Command seedgen ...
package main
```
或者
```go
// Program seedgen ...
package main
```
或者
```go
// The seedgen command ...
package main
```
或者
```go
// The seedgen program ...
package main
```
或者
```go
// Seedgen ..
package main
```

注意，以小写单词开始的句子包注释是不接受得，因为这些都是公开可见的，应该用正确的英文书写，包括将句子的第一个单词大写。当二进制名称
是第一个单词时，即使它与命令行调用的拼写不完全一致，也需要大写。

有关注释的更多信息，可以参考 [commentary](https://golang.org/doc/effective_go.html#commentary)

## Package Names
包名应该是全小写单词，不要使用下划线；包名应该尽可能简短。

## Pass Values
不要为了节省几个字节而传递指针作为函数参数。如果一个函数在整个过程中只把参数 `x` 作为 `*x`，那么这个参数不应该是一个指针。

除非要传递的是一个庞大的结构体或者可预知在将来会变得非常庞大的结构体，这个时候可以使用指针传递。

## Receiver Names
结构体函数中，接收器的命名不应该采用 "me"，"this"，"self" 等通用的名字，而应该采用简短的 1 或 2 个字符（例如 "Client" 的接收器命名
为 "c" 或 "cl"）并且能反映出结构体名的命名风格。

这个名字不需要像方法参数那样具有描述性，因为它的作用是显而易见的。它应该很简短，因为它可能会出现在该类型的每个方法的每一行中；并且
要保持一致：如果在一个方法中称接收方为 "c"，不要在另一个方法中称它为 "cl"。

## Receiver Type
接收器的类型应该选择值还是指针？

如果有疑问，那就使用指针。

但有时使用值接收器也是有意义的，通常是为了效率，例如对于一个小的不变的结构体或基本类型的值，使用值接收器。

一些有用的建议：

- 如果接收器是一个 `map`, `chan`, `func`, 不要使用指针，因为它们本身就是引用类型。
- 如果接收器是 `slice`，而这个方法不会对 `slice` 进行重新切片或者重新分配空间，不要使用指针。
- 如果方法需要修改接收器，那么必须使用指针。
- 如果接收器是一个结构体，并且包含了 `sync.Mutex` 或者类似的用于同步的成员。那么必须使用指针，避免成员拷贝。
- 如果接收器类型是一个很大的结构体，或者是一个大数组，建议使用指针来提高性能。
- 如果接收器是结构体，数组或 `slice`，并且其中的元素是指针，并且方法内部可能修改这些元素，那么建议使用指针。这能使方法的语义更加明确。
- 如果接收器是小型结构体，小数组，并且不需要修改里面的元素，里面的元素又是一些基础类型，建议使用值。

## Useful Test Failures
测试失败时，应该提供有用的信息（输入是什么，实际得到了什么，以及预期的结果）来说明出现了什么错误。
一个典型的示例：
```go
if got != tt.want {
	t.Errorf("Foo(%q) = %d; want %d", tt.in, got, tt.want) // or Fatalf, if test can't test anything more past this point
}
```

注意，这里的顺序是 `实际 != 预期`，输出信息也应该使用这个顺序。有些测试框架鼓励倒着写。而 Go 并不是。

如果测试用例比较多，可以写一个 [table-driven test](https://github.com/golang/go/wiki/TableDrivenTests)。

另一个消除失败测试的常用技巧，用不同的 TestFoo 函数包装每个调用者。

```go
func TestSingleValue(t *testing.T) { testHelper(t, []int{80}) }
func TestNoValues(t *testing.T)    { testHelper(t, []int{}) }
```



总之，任何情况下，你都应该给将来调试你的代码的人一个有用的错误信息。

## Variable Names
Go 中的变量名是简短的，局部变量更是如此。例如用 `c` 来替代 `lineCount`。用 `i` 来代替 `sliceIndex`。

基本规则：**名字离它的声明越远，描述性越强**。例如方法的接收器，常见的变量，如循环索引，可以是一个字母 "i"。但是特殊的变量和全局变
量可以使用有更多的描述性的长命名。

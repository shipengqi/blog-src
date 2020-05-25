---
title: go-range
tags:
---

遍历过程中并没有返回集合中的实际元素，而是将实际元素的值复制给了一个在此过程中固定的临时变量。
for range每次循环使用的是同一个临时变量！每次都是做了一次值拷贝而已，引用它的指针是有问题的！

```go
func ForSlice(s []string) {
    len := len(s)
    for i := 0; i < len; i++ {
        _, _ = i, s[i]
    }
}
 
func RangeForSlice(s []string) {
    for i, v := range s {
        _, _ = i, v
    }
}

```
测试
```go

import "testing"
 
const N  =  1000
 
func initSlice() []string{
    s:=make([]string,N)
    for i:=0;i<N;i++{
        s[i]="www.flysnow.org"
    }
    return s;
}
 
func BenchmarkForSlice(b *testing.B) {
    s:=initSlice()
 
    b.ResetTimer()
    for i:=0; i<b.N;i++  {
        ForSlice(s)
    }
}
 
func BenchmarkRangeForSlice(b *testing.B) {
    s:=initSlice()
 
    b.ResetTimer()
    for i:=0; i<b.N;i++  {
        RangeForSlice(s)
    }
}
```

```sh
BenchmarkForSlice-4              5000000    287 ns/op
BenchmarkRangeForSlice-4         3000000    509 ns/op
```
从性能测试可以看到，常规的for循环，要比for range的性能高出近一倍，到这里相信大家已经知道了原因，没错，因为for range每次是对循环元素的拷贝，所以
集合内的预算越复杂，性能越差，而反观常规的for循环，它获取集合内元素是通过s[i]，这种索引指针引用的方式，要比拷贝
性能要高的多。


既然是元素拷贝的问题，我们迭代 Slice 切片的目的也是为了获取元素，那么我们换一种方式实现for range。

```go
func RangeForSlice(s []string) {
    for i, _ := range s {
        _, _ = i, s[i]
    }
}
```

```sh
BenchmarkForSlice-4              5000000    280 ns/op
BenchmarkRangeForSlice-4         5000000    277 ns/op
```
和我们想的一样，性能上来了，和常规的for循环持平了。


```go
func main() {
	arr := []int{1, 2, 3}
	for i, v := range arr {
		fmt.Println(i)
		arr = append(arr, v)
	}
	fmt.Println(arr)
}

// 输出
// 0
// 1
// 2
// [1 2 3 1 2 3]
```


遍历切片时追加的元素不会增加循环的执行次数

```go
func main() {
	arr := []int{1, 2, 3}
	newArr := []*int{}
	for _, v := range arr {
		newArr = append(newArr, &v)
	}
	for _, v := range newArr {
		fmt.Println(*v)
	}
}

// 输出
// 3 3 3
```

正确的做法应该是使用 `&arr[i]` 替代 `&v`

```go
func main() {
	arr := []int{1, 2, 3}
	for i, _ := range arr {
		arr[i] = 0
	}
}
```

为数组、切片和哈希表占用的内存空间都是连续的，所以最快的方法是直接清空这片内存中的内容
编译上述代码时会得到以下的汇编指令：
```sh
"".main STEXT size=93 args=0x0 locals=0x30
	0x0000 00000 (main.go:3)	TEXT	"".main(SB), $48-0
	...
	0x001d 00029 (main.go:4)	MOVQ	"".statictmp_0(SB), AX
	0x0024 00036 (main.go:4)	MOVQ	AX, ""..autotmp_3+16(SP)
	0x0029 00041 (main.go:4)	MOVUPS	"".statictmp_0+8(SB), X0
	0x0030 00048 (main.go:4)	MOVUPS	X0, ""..autotmp_3+24(SP)
	0x0035 00053 (main.go:5)	PCDATA	$2, $1
	0x0035 00053 (main.go:5)	LEAQ	""..autotmp_3+16(SP), AX
	0x003a 00058 (main.go:5)	PCDATA	$2, $0
	0x003a 00058 (main.go:5)	MOVQ	AX, (SP)
	0x003e 00062 (main.go:5)	MOVQ	$24, 8(SP)
	0x0047 00071 (main.go:5)	CALL	runtime.memclrNoHeapPointers(SB)
	...
```

编译器会直接使用 `runtime.memclrNoHeapPointers` 清空切片中的数据



Go 语言中使用 range 遍历哈希表时，每次运行时都会打印出不同的结果：
```go
func main() {
	hash := map[string]int{
		"1": 1,
		"2": 2,
		"3": 3,
	}
	for k, v := range hash {
		println(k, v)
	}
}
```

这是 Go 语言故意的设计，它在运行时为哈希表的遍历引入不确定性，也是告诉所有使用 Go 语言的使用者，程序不要依赖于哈希表的稳定遍历


## 经典循环
Go 语言中的经典循环在编译器看来是一个 **`OFOR` 类型的节点**，四个部分组成：
初始化循环的 Ninit；
循环的继续条件 Left；
循环体结束时执行的 Right；
循环体 NBody：

```go
for Ninit; Left; Right {
    NBody
}
```

## 范围循环
编译器会在编译期间将所有 for/range 循环变成的经典循环

将 `ORANGE` 类型的节点转换成 `OFOR` 节点:
所有的 for/range 循环都会被 `cmd/compile/internal/gc/range.go` 中的 `walkrange` 函数转换成不包含复杂结构、只包含基本表达式的语句


### 数组和切片
```go
func walkrange(n *Node) *Node {
	if isMapClear(n) {
		m := n.Right
		lno := setlineno(m)
		n = mapClear(m)
		lineno = lno
		return n
	}

	// variable name conventions:
	//	ohv1, hv1, hv2: hidden (old) val 1, 2
	//	ha, hit: hidden aggregate, iterator
	//	hn, hp: hidden len, pointer
	//	hb: hidden bool
	//	a, v1, v2: not hidden aggregate, val 1, 2

	t := n.Type

	a := n.Right
	lno := setlineno(a)
	n.Right = nil

	var v1, v2 *Node
	l := n.List.Len()
	if l > 0 {
		v1 = n.List.First()
	}

	if l > 1 {
		v2 = n.List.Second()
	}

	if v2.isBlank() {
		v2 = nil
	}

	if v1.isBlank() && v2 == nil {
		v1 = nil
	}

	if v1 == nil && v2 != nil {
		Fatalf("walkrange: v2 != nil while v1 == nil")
	}

	// n.List has no meaning anymore, clear it
	// to avoid erroneous processing by racewalk.
	n.List.Set(nil)

	var ifGuard *Node

	translatedLoopOp := OFOR

	var body []*Node
	var init []*Node
	switch t.Etype {
	default:
		Fatalf("walkrange")

	case TARRAY, TSLICE:
        // 分析遍历数组和切片清空元素的情况
		if arrayClear(n, v1, v2, a) {
			lineno = lno
			return n
		}

		// orderstmt arranged for a copy of the array/slice variable if needed.
		ha := a

		hv1 := temp(types.Types[TINT])
		hn := temp(types.Types[TINT])

		init = append(init, nod(OAS, hv1, nil))
		init = append(init, nod(OAS, hn, nod(OLEN, ha, nil)))
        // 设置 for 循环的 Left 和 Right 字段
		n.Left = nod(OLT, hv1, hn)
		n.Right = nod(OAS, hv1, nod(OADD, hv1, nodintconst(1)))
		
        // 表示循环不关心数组的索引和数据
		// for range ha { body }
		if v1 == nil {
			break
		}

        // 遍历数组时需要使用索引，不关心数组的元素
		// for v1 := range ha { body }
		if v2 == nil {
			body = []*Node{nod(OAS, v1, hv1)}
			break
		}

        // 同时去遍历索引和元素的情况
		// for v1, v2 := range ha { body }
		if cheapComputableIndex(n.Type.Elem().Width) {
			// v1, v2 = hv1, ha[hv1]
			tmp := nod(OINDEX, ha, hv1)
			tmp.SetBounded(true)
			// Use OAS2 to correctly handle assignments
			// of the form "v1, a[v1] := range".
			a := nod(OAS2, nil, nil)
			a.List.Set2(v1, v2)
			a.Rlist.Set2(hv1, tmp)
			body = []*Node{a}
			break
		}

		// TODO(austin): OFORUNTIL is a strange beast, but is
		// necessary for expressing the control flow we need
		// while also making "break" and "continue" work. It
		// would be nice to just lower ORANGE during SSA, but
		// racewalk needs to see many of the operations
		// involved in ORANGE's implementation. If racewalk
		// moves into SSA, consider moving ORANGE into SSA and
		// eliminating OFORUNTIL.

		// TODO(austin): OFORUNTIL inhibits bounds-check
		// elimination on the index variable (see #20711).
		// Enhance the prove pass to understand this.
		ifGuard = nod(OIF, nil, nil)
		ifGuard.Left = nod(OLT, hv1, hn)
		translatedLoopOp = OFORUNTIL

		hp := temp(types.NewPtr(n.Type.Elem()))
		tmp := nod(OINDEX, ha, nodintconst(0))
		tmp.SetBounded(true)
		init = append(init, nod(OAS, hp, nod(OADDR, tmp, nil)))

		// Use OAS2 to correctly handle assignments
		// of the form "v1, a[v1] := range".
		a := nod(OAS2, nil, nil)
		a.List.Set2(v1, v2)
		a.Rlist.Set2(hv1, nod(ODEREF, hp, nil))
		body = append(body, a)

		// Advance pointer as part of the late increment.
		//
		// This runs *after* the condition check, so we know
		// advancing the pointer is safe and won't go past the
		// end of the allocation.
		a = nod(OAS, hp, addptr(hp, t.Elem().Width))
		a = typecheck(a, ctxStmt)
		n.List.Set1(a)
```

1. 使用 for range a {} 遍历数组和切片，不关心索引和数据的情况；
会被编译器转换为：
```go
ha := a
hv1 := 0
hn := len(ha)
v1 := hv1
for ; hv1 < hn; hv1++ {
    ...
}
```
2. 使用 for i := range a {} 遍历数组和切片，只关心索引的情况；
会被编译器转换为：
```go
ha := a
hv1 := 0
hn := len(ha)
v1 := hv1
for ; hv1 < hn; hv1++ {
    v1 := hv1
    ...
}
```
3. 使用 for i, elem := range a {} 遍历数组和切片，关心索引和数据的情况；
会被编译器转换为
```go
ha := a
hv1 := 0
hn := len(ha)
v1 := hv1
for ; hv1 < hn; hv1++ {
    tmp := ha[hv1]
    v1, v2 := hv1, tmp
    ...
}
```

对于所有的 range 循环，Go 语言都会在编译期将原切片或者数组赋值给一个新的变量 ha，在赋值的过程中就发生了**拷贝**
所以我们遍历的切片已经不是原始的切片变量了。

而遇到这种同时遍历索引和元素的 range 循环时，Go 语言会额外创建一个新的 v2 变量存储切片中的元素，
**循环中使用的这个变量 v2 会在每一次迭代被重新赋值而覆盖，在赋值时也发生了拷贝**。

`arrayClear` 会优化 Go 语言遍历数组或者切片并删除全部元素的逻辑：
```go
// original
for i := range a {
	a[i] = zero
}

// optimized
if len(a) != 0 {
	hp = &a[0]
	hn = len(a)*sizeof(elem(a))
	memclrNoHeapPointers(hp, hn)
	i = len(a) - 1
}
```

相比于依次清除数组或者切片中的数据，Go 语言会直接使用 `runtime.memclrNoHeapPointers` 或者 `runtime.memclrHasPointers` 
函数直接清除目标数组对应内存空间中的数据，并在执行完成后更新用于遍历数组的索引



## map
遍历 map 时，编译器会使用 `runtime.mapiterinit` 和 `runtime.mapiternext` 两个运行时函数重写原始的 `for/range` 循环：

```go
	case TMAP:
		// orderstmt allocated the iterator for us.
		// we only use a once, so no copy needed.
		ha := a

		hit := prealloc[n]
		th := hit.Type
		n.Left = nil
		keysym := th.Field(0).Sym  // depends on layout of iterator struct.  See reflect.go:hiter
		elemsym := th.Field(1).Sym // ditto

		fn := syslook("mapiterinit")

		fn = substArgTypes(fn, t.Key(), t.Elem(), th)
		init = append(init, mkcall1(fn, nil, nil, typename(t), ha, nod(OADDR, hit, nil)))
		n.Left = nod(ONE, nodSym(ODOT, hit, keysym), nodnil())

		fn = syslook("mapiternext")
		fn = substArgTypes(fn, th)
		n.Right = mkcall1(fn, nil, nil, nod(OADDR, hit, nil))

		key := nodSym(ODOT, hit, keysym)
		key = nod(ODEREF, key, nil)
		if v1 == nil {
			body = nil
		} else if v2 == nil {
			body = []*Node{nod(OAS, v1, key)}
		} else {
			elem := nodSym(ODOT, hit, elemsym)
			elem = nod(ODEREF, elem, nil)
			a := nod(OAS2, nil, nil)
			a.List.Set2(v1, v2)
			a.Rlist.Set2(key, elem)
			body = []*Node{a}
		}
```

```go
ha := a
hit := hiter(n.Type)
th := hit.Type
mapiterinit(typename(t), ha, &hit)
for ; hit.key != nil; mapiternext(&hit) {
    key := *hit.key
    val := *hit.val
}
```
上述代码是 `for key, val := range map {}` 生成的

在 `walkrange` 函数处理 `TMAP` 节点时会根据接受 `range` 返回值的数量在循环体中插入需要的赋值语句：
1. `for range hash{}`   -> `nil`
2. `for k := range hash{}` -> `k := *hit.key`
3. `for k , v := range hash{}` -> `k := *hit.key, v := *hit.value`

三种不同的情况会分别向循环体插入不同的赋值语句。遍历哈希表时会使用 `runtime.mapiterinit` 函数初始化遍历开始的元素：
```go
func mapiterinit(t *maptype, h *hmap, it *hiter) {
	it.t = t
	it.h = h
	it.B = h.B
	it.buckets = h.buckets

	r := uintptr(fastrand())
	it.startBucket = r & bucketMask(h.B)
	it.offset = uint8(r >> h.B & (bucketCnt - 1))
	it.bucket = it.startBucket
	mapiternext(it)
}
```

该函数会初始化 hiter 结构体中的字段，并通过 `runtime.fastrand` 生成一个随机数帮助我们随机选择一个桶开始遍历。保证遍历的随机性。

```go
func mapiternext(it *hiter) {
	h := it.h
	t := it.t
	bucket := it.bucket
	b := it.bptr
	i := it.i
	alg := t.key.alg

next:
	if b == nil {
		if bucket == it.startBucket && it.wrapped {
			it.key = nil
			it.value = nil
			return
		}
		b = (*bmap)(add(it.buckets, bucket*uintptr(t.bucketsize)))
		bucket++
		if bucket == bucketShift(it.B) {
			bucket = 0
			it.wrapped = true
		}
		i = 0
	}
```

这段代码主要有两个作用：
1. 在待遍历的桶为空时选择需要遍历的新桶；
2. 在不存在待遍历的桶时返回 (`nil`, `nil`) 键值对并中止遍历过程；


### 字符串
遍历字符串的过程与数组、切片和哈希表非常相似，只是在遍历时会获取字符串中索引对应的字节并将字节转换成 `rune`。
`for i, r := range s {}` 的结构都会被转换成如下所示的形式：

```go
ha := s
for hv1 := 0; hv1 < len(ha); {
    hv1t := hv1
    hv2 := rune(ha[hv1])
    if hv2 < utf8.RuneSelf {
        hv1++
    } else {
        hv2, hv1 = decoderune(h1, hv1)
    }
    v1, v2 = hv1t, hv2
}
```
### channel
`for v := range ch {}` 的语句最终会被转换成如下的格式：
```go
ha := a
hv1, hb := <-ha
for ; hb != false; hv1, hb = <-ha {
    v1 := hv1
    hv1 = nil
    ...
}
```
该循环会使用 `<-ch` 从管道中取出等待处理的值，这个操作会调用 `runtime.chanrecv2` 并阻塞当前的协程，当 `runtime.chanrecv2` 返回时会根据
布尔值 hb 判断当前的值是否存在，如果不存在就意味着当前的管道已经被关闭了，如果存在就会为 v1 赋值并清除 hv1 变量中的数据，然后会重新陷入阻塞等待新数据。

---
title: 笔记 鸟哥的Linux私房菜（中）
date: 2018-12-24 15:26:39
categories: ["Linux"]
---

Linux 最传统的磁盘文件系统 （filesystem） 使用的是 EXT2 ！所以要了解 Linux 的文件系统就得要由认识 EXT2 开始。

<!-- more -->

## Linux 磁盘与文件系统管理
磁盘的物理组成：
- 圆形的盘片（主要记录数据的部分）；
- 机械手臂，与在机械手臂上的磁头（可读写盘片上的数据）；
- 主轴马达，可以转动盘片，让机械手臂的磁头在盘片上读写数据。

Linux 操作系统的文件权限（rwx）与文件属性（拥有者、群组、时间参数等）。 文件系统通常会将这两部份的数据分别存放在不同的区块，权限与属性放置到 inode 中，至于实际数据则放置到 data block 区块中。
另外，还有一个超级区块 （superblock） 会记录整个文件系统的整体信息，包括 inode 与 block 的总量、使用量、剩余量等。

- superblock：记录此 filesystem 的整体信息，包括inode/block的总量、使用量、剩余量， 以及文件系统的格式与相关信息等；
- inode：记录文件的属性，一个文件占用一个inode，同时记录此文件的数据所在的 block 号码；
- block：实际记录文件的内容，若文件太大时，会占用多个 block 。

由于每个 inode 与 block 都有编号，而每个文件都会占用一个 inode ，inode 内则有文件数据放置的 block 号码。如果能够找到文件的 inode 的话，那么自然就会知道这个文件所放置数据的 block 号码，
当然也就能够读出该文件的实际数据了。这种数据存取的方法我们称为**索引式文件系统（indexed allocation）**。

![](/images/linux-basic/filesystem1.png)

我们惯用的U盘（闪存），U盘使用的文件系统一般为 FAT 格式。FAT 这种格式的文件系统并没有 inode 存在，所以 FAT 没有办法将这个文件的所有 block 在一开始就读取出来。每个 block 号码都记录在前
一个 block 当中。

![](/images/linux-basic/filesystem2.png)

上图中我们假设文件的数据依序写入1->7->4->15号这四个 block 号码中， 但这个文件系统没有办法一口气就知道四个 block 的号码，他得要一个一个的将 block 读出后，才会知道下一个 block 在何处。
如果同一个文件数据写入的 block 分散的太过厉害时，则我们的磁头将无法在磁盘转一圈就读到所有的数据，因此磁盘就会多转好几圈才能完整的读取到这个文件的内容。

所谓的“磁盘重组”就是文件写入的 block 太过于离散了，此时文件读取的性能将会变的很差所致。这个时候可以通过磁盘重组将同一个文件所属的 blocks 汇整在一起，这样数据的读取会比较容易。

FAT 的文件系统需要三不五时的磁盘重组一下，但是 Ext2 是索引式文件系统，基本上不太需要常常进行磁盘重组。但是如果文件系统使用太久， 常常删除/编辑/新增文件时，那么还是可能会造成文件数据太过于离散的问题，
此时或许会需要进行重整一下。

### EXT2 文件系统（inode）
文件系统一开始就将 inode 与 block 规划好了，除非重新格式化，否则 inode 与 block 固定后就不再变动。但是如果文件系统高达数百GB时，那么将所有的 inode 与 block 放置在一起将是很不智的决定，
因为 inode 与 block 的数量太庞大，不容易管理。

因此，**Ext2 文件系统在格式化的时候基本上是区分为多个区块群组 （block group） 的，每个区块群组都有独立的 inode/block/superblock 系统**。

#### data block （数据区块）
Ext2 文件系统中所支持的 block 大小有 1K, 2K 及 4K 三种。由于 block 大小的差异，会导致该文件系统能够支持的最大磁盘容量与最大单一文件大小并不相同。

| Block 大小      | 1KB   | 2KB   | 4KB   |
| --------   | -----  | -----  | -----  |
| 最大单一文件限制  | 16GB | 256GB | 2TB |
| 最大文件系统总容量  | 2TB | 8TB | 16TB |

Ext2 文件系统的 block 的其他限制：
- 原则上，block 的大小与数量在格式化完就不能够再改变了（除非重新格式化）
- 每个 block 内最多只能够放置一个文件的数据
- 承上，如果文件大于 block 的大小，则一个文件会占用多个 block 数量
- 承上，若文件小于 block ，则该 block 的剩余容量就不能够再被使用了（磁盘空间会浪费）

#### inode table （inode 表格）
- inode 记录的文件数据至少有下面这些：
- 该文件的存取模式（read/write/excute）；
- 该文件的拥有者与群组（owner/group）；
- 该文件的容量；
- 该文件创建或状态改变的时间（ctime）；
- 最近一次的读取时间（atime）；
- 最近修改的时间（mtime）；
- 定义文件特性的旗标（flag），如 SetUID...；
- 该文件真正内容的指向 （pointer）；

inode 的数量与大小也是在格式化时就已经固定了，除此之外 inode 还有些什么特色：
- 每个 inode 大小均固定为 128 Bytes （新的 ext4 与 xfs 可设置到 256 Bytes）；
- 每个文件都仅会占用一个 inode 而已；
- 承上，因此文件系统能够创建的文件数量与 inode 的数量有关；
- 系统读取文件时需要先找到 inode，并分析 inode 所记录的权限与使用者是否符合，若符合才能够开始实际读取 block 的内容。

#### Superblock （超级区块）
Superblock 是记录整个 filesystem 相关信息的地方， 没有 Superblock ，就没有这个 filesystem 了。他记录的信息主要有：
- block 与 inode 的总量；
- 未使用与已使用的 inode / block 数量；
- block 与 inode 的大小 （block 为 1, 2, 4K，inode 为 128Bytes 或 256Bytes）；
- filesystem 的挂载时间、最近一次写入数据的时间、最近一次检验磁盘 （fsck） 的时间等文件系统的相关信息；
- 一个 valid bit 数值，若此文件系统已被挂载，则 valid bit 为 0 ，若未被挂载，则 valid bit 为 1 。

一般来说， superblock 的大小为 1024Bytes。

#### Filesystem Description （文件系统描述说明）
这个区段可以描述每个 block group 的开始与结束的 block 号码，以及说明每个区段 （superblock, bitmap, inodemap, data block） 分别介于哪一个 block 号码之间。

#### block bitmap （区块对照表）
想要新增文件时总会用到 block，那你要使用哪个 block 来记录呢？当然是选择“空的 block ”来记录新文件的数据。那怎么知道哪个 block 是空的？这就得要通过 block bitmap 的辅助了。
从 block bitmap 当中可以知道哪些 block 是空的，因此我们的系统就能够很快速的找到可使用的空间来处置文件。

#### inode bitmap （inode 对照表）
与 block bitmap 是类似的功能。

#### dumpe2fs： 查询 Ext 家族 superblock 信息的指令
```bash
dumpe2fs [-bh] 设备文件名
选项与参数：
-b ：列出保留为坏轨的部分
-h ：仅列出 superblock 的数据，不会列出其他的区段内容
```

### 与目录树的关系
我们知道在 Linux 系统下，每个文件（不管是一般文件还是目录文件）都会占用一个 inode ， 且可依据文件内容的大小来分配多个 block 给该文件使用。

目录与文件在文件系统当中是如何记录数据的?

#### 目录
在 Linux 下的文件系统创建一个目录时，**文件系统会分配一个 inode 与至少一块 block 给该目录。inode 记录该目录的相关权限与属性，并可记录分配到的那块 block 号码；
而 block 则是记录在这个目录下的文件名与该文件名占用的 inode 号码数据**。

想要实际观察 root 主文件夹内的文件所占用的 inode 号码时，可以使用 ls -i 这个选项来处理：
```bash
[root@study ~]# ls -li
total 8
53735697 -rw-------. 1 root root 1816 May  4 17:57 anaconda-ks.cfg
53745858 -rw-r--r--. 1 root root 1864 May  4 18:01 initial-setup-ks.cfg
```

#### 文件
在 Linux 下的 ext2 创建一个一般文件时， ext2 会分配一个 inode 与相对于该文件大小的 block 数量给该文件。

**假设我的一个 block 为 4 KBytes ，而我要创建一个 100 KBytes 的文件，那么 linux 将分配一个 inode 与 25 个 block 来储存该文件**。

#### 目录树读取
上面我们知道**文件名是记录在目录的 block 当中**， 因此当我们要**读取某个文件时，就必会经过目录的 inode 与 block ，然后才能够找到那个待读取文件的 inode 号码**，
最终才会读到正确的文件的 block 内的数据。

由于目录树是由根目录开始读起，因此系统通过挂载的信息可以找到挂载点的 inode 号码，此时就能够得到根目录的 inode 内容，并依据该 inode 读取根目录的 block 内的文件名数据，
再一层一层的往下读到正确的文件名。

如果我想要读取 /etc/passwd 这个文件时，系统是如何读取的？
```bash
[root@study ~]# ll -di / /etc /etc/passwd
 128 dr-xr-xr-x.  17 root root 4096 May  4 17:56 /
33595521 drwxr-xr-x. 131 root root 8192 Jun 17 00:20 /etc
36628004 -rw-r--r--.   1 root root 2092 Jun 17 00:20 /etc/passwd
```

该文件的读取流程为（假设读取者身份为 dmtsai 这个一般身份使用者）：
1. `/`的 inode： 通过挂载点的信息找到 inode 号码为 128 的根目录 inode，且 inode 规范的权限让我们可以读取该 block 的内容（有 r 与 x） ；
2. `/`的 block： 经过上个步骤取得 block 的号码，并找到该内容有 etc/ 目录的 inode 号码 （33595521）；
3. `etc/`的 inode： 读取 33595521 号 inode 得知 dmtsai 具有 r 与 x 的权限，因此可以读取 etc/ 的 block 内容；
4. `etc/`的 block： 经过上个步骤取得 block 号码，并找到该内容有 passwd 文件的 inode 号码 （36628004）；
5. `passwd`的 inode： 读取 36628004 号 inode 得知 dmtsai 具有 r 的权限，因此可以读取 passwd 的 block 内容；
6. `passwd`的 block： 最后将该 block 内容的数据读出来。

#### filesystem 大小与磁盘读取性能
关于文件系统的使用效率上，当你的一个文件系统规划的很大时，例如 100GB 这么大时， 由于磁盘上面的数据总是来来去去的，所以，整个文件系统上面的文件通常无法连续写在一起（block 号码不会连续的意思），
而是填入式的将数据填入没有被使用的 block 当中。如果文件写入的 block 真的分的很散， 此时就会有所谓的文件数据离散的问题发生了。

虽然我们的 ext2 在 inode 处已经将该文件所记录的 block 号码都记上了， 所以数据可以一次性读取，但是如果文件真的太过离散，确实还是会发生读取效率低落的问题。 因为磁头还是得要在整个文件系统中来来去去的频
繁读取。果真如此，那么可以将整个 filesystme 内的数据全部复制出来，将该 filesystem 重新格式化， 再将数据给他复制回去即可解决这个问题。

此外，如果 filesystem 真的太大了，那么当一个文件分别记录在这个文件系统的最前面与最后面的 block 号码中， 此时会造成磁盘的机械手臂移动幅度过大，也会造成数据读取性能的低落。而且磁头在搜寻整个 filesystem 时，
也会花费比较多的时间去搜寻！因此，partition 的规划并不是越大越好，而是真的要针对你的主机用途来进行规划才行。

### EXT2/EXT3/EXT4 文件的存取与日志式文件系统的功能
上面说到的都是读取，如果是新建一个文件或目录时，我们的文件系统是如何处理的呢？ 这个时候就得要 block bitmap 及 inode bitmap 的帮忙了。
假设我们想要新增一个文件，此时文件系统的行为是：
1. 先确定使用者对于欲新增文件的目录是否具有 w 与 x 的权限，若有的话才能新增；
2. 根据 inode bitmap 找到没有使用的 inode 号码，并将新文件的权限/属性写入；
3. 根据 block bitmap 找到没有使用中的 block 号码，并将实际的数据写入 block 中，且更新 inode 的 block 指向数据；
4. 将刚刚写入的 inode 与 block 数据同步更新 inode bitmap 与 block bitmap，并更新 superblock 的内容。

**一般来说，我们将 inode table 与 data block 称为数据存放区域，至于其他例如 superblock、 block bitmap 与 inode bitmap 等区段就被称为 metadata （中介数据）**。

#### 数据的不一致 （Inconsistent） 状态

如果你的文件在写入文件系统时，因为不知名原因导致系统中断（例如突然的停电啊、 系统核心发生错误啊～等等的怪事发生时），所以写入的数据仅有 inode table 及 data block 而已， 最后一个同步更新中介数据的步骤
并没有做完，此时就会发生 metadata 的内容与实际数据存放区产生不一致 （Inconsistent） 的情况了。

为了解决这个问题，出现了日志式文件系统。

#### 日志式文件系统 （Journaling filesystem）
在我们的 filesystem 当中规划出一个区块，该区块专门在记录写入或修订文件时的步骤， 那不就可以简化一致性检查的步骤了？也就是说：
1. 预备：当系统要写入一个文件时，会先在日志记录区块中纪录某个文件准备要写入的信息；
2. 实际写入：开始写入文件的权限与数据；开始更新 metadata 的数据；
3. 结束：完成数据与 metadata 的更新后，在日志记录区块当中完成该文件的纪录。

万一数据的纪录过程当中发生了问题，那么我们的系统只要去检查日志记录区块， 就可以知道哪个文件发生了问题，针对该问题来做一致性的检查即可，而不必针对整块 filesystem 去检查。

### Linux 文件系统的运行

我们知道，所有的数据都得要载入到内存后 CPU 才能够对该数据进行处理。如果你常常编辑一个好大的文件，在编辑的过程中又频繁的要系统来写入到磁盘中，由于磁盘写入的速度要比内存慢很多，
因此你会常常耗在等待磁盘的写入/读取上。

为了解决这个效率的问题，inux 使用的方式是通过一个称为**非同步处理（asynchronously）**的方式。所谓的非同步处理是这样的：

当系统载入一个文件到内存后，如果该文件没有被更动过，则在内存区段的文件数据会被设置为干净（clean）的。 但如果内存中的文件数据被更改过了（例如你用 nano 去编辑过这个文件），
此时该内存中的数据会被设置为脏的 （Dirty）。此时所有的动作都还在内存中执行，并没有写入到磁盘中！ 系统会不定时的将内存中设置为“Dirty”的数据写回磁盘，以保持磁盘与内存数据的一致性。

Linux 系统文件系统与内存有非常大的关系:
- 系统会将常用的文件数据放置到内存的缓冲区，以加速文件系统的读/写；
- 承上，因此 Linux 的实体内存最后都会被用光！这是正常的情况！可加速系统性能；
- 你可以手动使用`sync`来强迫内存中设置为 Dirty 的文件回写到磁盘中；
- 若正常关机时，关机指令会主动调用`sync`来将内存的数据回写入磁盘内；
- 但若不正常关机（如跳电、死机或其他不明原因），由于数据尚未回写到磁盘内， 此重新开机后可能会花很多时间在进行磁盘检验，甚至可能导致文件系统的损毁（非磁盘损毁）。

### 挂载点的意义 （mount point）
**将文件系统与目录树结合的动作我们称为“挂载”**。挂载点一定是目录，该目录为进入该文件系统的入口。 因此并不是你有任何文件系统都能使用，必须要“挂载”到目录树的某个目录后，
才能够使用该文件系统的。

### 其他 Linux 支持的文件系统与 VFS
常见的支持文件系统有：
- 传统文件系统：ext2 / minix / MS-DOS / FAT （用 vfat 模块） / iso9660 （光盘）等等；
- 日志式文件系统： ext3 /ext4 / ReiserFS / Windows' NTFS / IBM's JFS / SGI's XFS / ZFS
- 网络文件系统： NFS / SMBFS

#### Linux VFS （Virtual Filesystem Switch）
Linux 的核心是如何管理这些认识的文件系统？其实，**整个 Linux 的系统都是通过一个名为 Virtual Filesystem Switch 的核心功能去读取 filesystem 的**。
也就是说，整个 Linux 认识的 filesystem 其实都是 VFS 在进行管理，使用者并不需要知道每个 partition 上头的 filesystem 是什么，VFS 会主动的帮我们做好读取的动作。

### XFS 文件系统
CentOS 为什么舍弃对 Linux 支持度最完整的 EXT 家族而改用 XFS？
EXT 家族当前较伤脑筋的地方：支持度最广，但格式化超慢。
Ext 文件系统家族对于文件格式化的处理方面，采用的是预先规划出所有的 inode/block/meta data 等数据，未来系统可以直接取用，不需要再进行动态配置的作法。这个作法在早期磁盘容
量还不大的时候还算 OK，但时至今日，磁盘容量越来越大，连传统的 MBR 都已经被 GPT 所取代，现在都已经说到 PB 或 EB 以上容量了！可以想像，当你的 TB 以上等级的传统 ext 家族
文件系统在格式化的时候，光是系统要预先分配 inode 与 block 就消耗你好多好多的人类时间。

xfs 文件系统在数据的分布上，主要规划为三个部份，一个数据区 （data section）、一个文件系统活动登录区 （log section）以及一个实时运行区 （realtime section）。

#### 数据区
数据区就跟我们之前谈到的 ext 家族一样，包括 inode/data block/superblock 等数据，都放置在这个区块。这个数据区与 ext 家族的 block group 类似，
也是分为多个储存区群组（allocation groups）来分别放置文件系统所需要的数据。 每个储存区群组都包含了
1. 整个文件系统的 superblock
2. 剩余空间的管理机制
3. inode的分配与追踪

此外，inode与 block 都是系统需要用到时， 这才动态配置产生，所以格式化动作超级快。

#### 文件系统活动登录区
这个区域主要用来记录文件系统的变化，有点像是日志区。
#### 实时运行区
当文件要被创建时，xfs 会在这个区段找到一个到数个 extent 区块，将文件放置在这个区块，等到分配完毕后，再写入到 data section 的inode 和 block 中。
这个 extent 区块的大小得要在格式化的时候就先指定，最小值是 4K 最大可到 1G。

## 文件系统的简单操作
- df：列出文件系统的整体磁盘使用量；
- du：评估文件系统的磁盘使用量（常用在推估目录所占容量）

```bash
df [-ahikHTm] [目录或文件名]
选项与参数：
-a  ：列出所有的文件系统，包括系统特有的 /proc 等文件系统；
-k  ：以 KBytes 的容量显示各文件系统；
-m  ：以 MBytes 的容量显示各文件系统；
-h  ：以人们较易阅读的 GBytes, MBytes, KBytes 等格式自行显示；
-H  ：以 M=1000K 取代 M=1024K 的进位方式；
-T  ：连同该 partition 的 filesystem 名称 （例如 xfs） 也列出；
-i  ：不用磁盘容量，而以 inode 的数量来显示

du [-ahskm] 文件或目录名称
选项与参数：
-a  ：列出所有的文件与目录容量，因为默认仅统计目录下面的文件量而已。
-h  ：以人们较易读的容量格式 （G/M） 显示；
-s  ：列出总量而已，而不列出每个各别的目录占用容量；
-S  ：不包括子目录下的总计，与 -s 有点差别。
-k  ：以 KBytes 列出容量显示；
-m  ：以 MBytes 列出容量显示；
```

### 实体链接与符号链接： ln
Linux 下面的链接文件有两种，一种是类似 Windows 的捷径功能的文件，可以让你快速的链接到目标文件（或目录）；另一种则是**通过文件系统的 inode 链接来产生新文件名，
而不是产生新文件。这种称为实体链接（hard link）**。

#### hard link
- 每个文件都会占用一个 inode ，文件内容由 inode 的记录来指向
- 想要读取该文件，必须要经过目录记录的文件名来指向到正确的 inode 号码才能读取。

也就是说，其实文件名只与目录有关，但是文件内容则与 inode 有关。那么有没有可能有多个文件名对应到同一个 inode 号码？有的！那就是 hard link 的由来。
所以简单的说：**hard link 只是在某个目录下新增一笔文件名链接到某 inode 号码的关连记录而已**。（文件系统会分配一个 inode 与至少一块 block 给该目录。其中，inode 记录该目录的相关权限
与属性，并可记录分配到的那块 block 号码； 而 block 则是记录在这个目录下的文件名与该文件名占用的 inode 号码数据。）也就是说，新增一个文件名，会在目录的 block 记录文件名与对应的 inode
号码。

hard link 是有限制的：
- 不能跨 Filesystem；
- 不能 link 目录。

#### Symbolic Link （符号链接，亦即是捷径）
Symbolic link 就是在创建一个独立的文件，而这个文件会让数据的读取指向他 link 的那个文件的文件名！由于只是利用文件来做为指向的动作，所以，当来源文件被删除之后，symbolic link 的文件
会一直说“无法打开某文件！”。实际上就是找不到原始“文件名”而已。

Symbolic Link 与 Windows 的捷径可以给他划上等号，由 Symbolic link 所创建的文件为一个独立的新的文件，所以会占用掉 inode 与 block 。

```bash
[root@study ~]# ln -s /etc/crontab crontab2
[root@study ~]# ll -i /etc/crontab /root/crontab2
34474855 -rw-r--r--. 2 root root 451 Jun 10  2014 /etc/crontab
53745909 lrwxrwxrwx. 1 root root  12 Jun 23 22:31 /root/crontab2 -&gt; /etc/crontab
```

上表的结果我们可以知道两个文件指向不同的 inode 号码，当然就是两个独立的文件存在！ 而且链接文件的重要内容就是他会写上目标文件的“文件名”， 你可以发现为什么上表中链接文件的大小为 12 Bytes 呢？
因为箭头（->）右边的文件名“/etc/crontab”总共有 12 个英文，每个英文占用 1 个 Bytes ，所以文件大小就是 12Bytes了！

## 磁盘的分区、格式化、检验与挂载

1. `lsblk`列出系统上的所有磁盘列表
```bash
lsblk [-dfimpt] [device]
选项与参数：
-d  ：仅列出磁盘本身，并不会列出该磁盘的分区数据
-f  ：同时列出该磁盘内的文件系统名称
-i  ：使用 ASCII 的线段输出，不要使用复杂的编码 （再某些环境下很有用）
-m  ：同时输出该设备在 /dev 下面的权限数据 （rwx 的数据）
-p  ：列出该设备的完整文件名！而不是仅列出最后的名字而已。
-t  ：列出该磁盘设备的详细数据，包括磁盘伫列机制、预读写的数据量大小等

[root@study ~]# lsblk
NAME               MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sr0                  11:0    1 1024M  0 rom
vda                   8:0    0  200G  0 disk
├─vda1                8:1    0    2G  0 part /boot
├─vda2                8:2    0   58G  0 part
│ ├─rhel-root       253:0    0  191G  0 lvm  /
│ └─rhel-swap       253:1    0    6G  0 lvm
└─vda3                8:3    0  140G  0 part
  └─rhel-root       253:0    0  191G  0 lvm  /
```

从上面的输出我们可以很清楚的看到，目前的系统主要有个 sr0 以及一个 vda 的设备，而 vda 的设备下面又有三个分区， 其中 vda3 甚至还有因为 LVM 产生的文件系统

上面输出的信息：
- NAME：就是设备的文件名，会省略`/dev`等前导目录！
- MAJ:MIN：其实核心认识的设备都是通过这两个代码来熟悉的！分别是主要：次要设备代码！
- RM：是否为可卸载设备 （removable device），如光盘、USB 磁盘等等
- SIZE：容量
- RO：是否为只读设备的意思
- TYPE：是磁盘 （disk）、分区 （partition） 还是只读存储器 （rom） 等输出
- MOUTPOINT：挂载点


2. `blkid`列出设备的 UUID 等参数
3. `parted`列出磁盘的分区表类型与分区信息
```bash
parted device_name print
```

### 磁盘分区： gdisk/fdisk
**MBR 分区表使用 fdisk 分区，GPT 分区表使用 gdisk 分区**。

#### gdisk
```bash
[root@study ~]# gdisk 设备名称
```

**你应该要通过`lsblk`或`blkid`先找到磁盘，再用`parted /dev/xxx print`来找出内部的分区表类型，之后才用`gdisk`或`fdisk`来操作系统**。

### 磁盘格式化（创建文件系统）
分区完毕后自然就是要进行文件系统的格式化。

#### XFS 文件系统 mkfs.xfs
**“格式化”其实应该称为“创建文件系统 （make filesystem）”才对，所以使用的指令是 mkfs**。创建的 xfs 文件系统：
```bash
mkfs.xfs [-b bsize] [-d parms] [-i parms] [-l parms] [-L label] [-f] \
                         [-r parms] 设备名称
选项与参数：
关於单位：下面只要谈到“数值”时，没有加单位则为 Bytes 值，可以用 k,m,g,t,p （小写）等来解释
          比较特殊的是 s 这个单位，它指的是 sector 的“个数”喔！
-b  ：后面接的是 block 容量，可由 512 到 64k，不过最大容量限制为 Linux 的 4k 喔！
-d  ：后面接的是重要的 data section 的相关参数值，主要的值有：
      agcount=数值  ：设置需要几个储存群组的意思（AG），通常与 CPU 有关
      agsize=数值   ：每个 AG 设置为多少容量的意思，通常 agcount/agsize 只选一个设置即可
      file          ：指的是“格式化的设备是个文件而不是个设备”的意思！（例如虚拟磁盘）
      size=数值     ：data section 的容量，亦即你可以不将全部的设备容量用完的意思
      su=数值       ：当有 RAID 时，那个 stripe 数值的意思，与下面的 sw 搭配使用
      sw=数值       ：当有 RAID 时，用于储存数据的磁盘数量（须扣除备份碟与备用碟）
      sunit=数值    ：与 su 相当，不过单位使用的是“几个 sector（512Bytes大小）”的意思
      swidth=数值   ：就是 su*sw 的数值，但是以“几个 sector（512Bytes大小）”来设置
-f  ：如果设备内已经有文件系统，则需要使用这个 -f 来强制格式化才行！
-i  ：与 inode 有较相关的设置，主要的设置值有：
      size=数值     ：最小是 256Bytes 最大是 2k，一般保留 256 就足够使用了！
      internal=[0|1]：log 设备是否为内置？默认为 1 内置，如果要用外部设备，使用下面设置
      logdev=device ：log 设备为后面接的那个设备上头的意思，需设置 internal=0 才可！
      size=数值     ：指定这块登录区的容量，通常最小得要有 512 个 block，大约 2M 以上才行！
-L  ：后面接这个文件系统的标头名称 Label name 的意思！
-r  ：指定 realtime section 的相关设置值，常见的有：
      extsize=数值  ：就是那个重要的 extent 数值，一般不须设置，但有 RAID 时，
                      最好设置与 swidth 的数值相同较佳！最小为 4K 最大为 1G 。
```

#### EXT4 文件系统 mkfs.ext4
要格式化为 ext4 的传统 Linux 文件系统的话，可以使用`mkfs.ext4`这个指令。
```bash
mkfs.ext4 [-b size] [-L label] 设备名称
选项与参数：
-b  ：设置 block 的大小，有 1K, 2K, 4K 的容量，
-L  ：后面接这个设备的标头名称。
```

### 文件系统挂载与卸载
**挂载点是目录，而这个目录就是进入磁盘分区（其实是文件系统）的入口**。不过要进行挂载前，最好先确定几件事：
- 单一文件系统不应该被重复挂载在不同的挂载点（目录）中；
- 单一目录不应该重复挂载多个文件系统；
- 要作为挂载点的目录，理论上应该都是空目录才是。

要将文件系统挂载到 Linux 系统上，就要使用`mount`这个指令：
```bash
[root@study ~]# mount -a
[root@study ~]# mount [-l]
[root@study ~]# mount [-t 文件系统] LABEL=''  挂载点
[root@study ~]# mount [-t 文件系统] UUID=''   挂载点
[root@study ~]# mount [-t 文件系统] 设备文件名  挂载点
选项与参数：
-a  ：依照配置文件 [/etc/fstab](../Text/index.html#fstab) 的数据将所有未挂载的磁盘都挂载上来
-l  ：单纯的输入 mount 会显示目前挂载的信息。加上 -l 可增列 Label 名称！
-t  ：可以加上文件系统种类来指定欲挂载的类型。常见的 Linux 支持类型有：xfs, ext3, ext4,
      reiserfs, vfat, iso9660（光盘格式）, nfs, cifs, smbfs （后三种为网络文件系统类型）
-n  ：在默认的情况下，系统会将实际挂载的情况实时写入 /etc/mtab 中，以利其他程序的运行。
      但在某些情况下（例如单人维护模式）为了避免问题会刻意不写入。此时就得要使用 -n 选项。
-o  ：后面可以接一些挂载时额外加上的参数！比方说帐号、密码、读写权限等：
      async, sync:   此文件系统是否使用同步写入 （sync） 或非同步 （async） 的
                     内存机制，请参考[文件系统运行方式](../Text/index.html#harddisk-filerun)。默认为 async。
      atime,noatime: 是否修订文件的读取时间（atime）。为了性能，某些时刻可使用 noatime
      ro, rw:        挂载文件系统成为只读（ro） 或可读写（rw）
      auto, noauto:  允许此 filesystem 被以 mount -a 自动挂载（auto）
      dev, nodev:    是否允许此 filesystem 上，可创建设备文件？ dev 为可允许
      suid, nosuid:  是否允许此 filesystem 含有 suid/sgid 的文件格式？
      exec, noexec:  是否允许此 filesystem 上拥有可执行 binary 文件？
      user, nouser:  是否允许此 filesystem 让任何使用者执行 mount ？一般来说，
                     mount 仅有 root 可以进行，但下达 user 参数，则可让
                     一般 user 也能够对此 partition 进行 mount 。
      defaults:      默认值为：rw, suid, dev, exec, auto, nouser, and async
      remount:       重新挂载，这在系统出错，或重新更新参数时，很有用
```

#### 挂载 xfs/ext4/vfat 等文件系统
```bash
范例：找出 /dev/vda4 的 UUID 后，用该 UUID 来挂载文件系统到 /data/xfs 内
[root@study ~]# blkid /dev/vda4
/dev/vda4: UUID="e0a6af55-26e7-4cb7-a515-826a8bd29e90" TYPE="xfs"

[root@study ~]# mount UUID="e0a6af55-26e7-4cb7-a515-826a8bd29e90" /data/xfs
mount: mount point /data/xfs does not exist  # 非正规目录！所以手动创建它！

[root@study ~]# mkdir -p /data/xfs
[root@study ~]# mount UUID="e0a6af55-26e7-4cb7-a515-826a8bd29e90" /data/xfs
[root@study ~]# df /data/xfs
Filesystem     1K-blocks  Used Available Use% Mounted on
/dev/vda4        1038336 32864   1005472   4% /data/xfs
# 顺利挂载，且容量约为 1G 左右没问题！
```

#### 挂载 CD 或 DVD 光盘
```bash
范例：将你用来安装 Linux 的 CentOS 原版光盘拿出来挂载到 /data/cdrom！
[root@study ~]# blkid
.....（前面省略）.....
/dev/sr0: UUID="2015-04-01-00-21-36-00" LABEL="CentOS 7 x86_64" TYPE="iso9660" PTTYPE="dos"

[root@study ~]# mkdir /data/cdrom
[root@study ~]# mount /dev/sr0 /data/cdrom
mount: /dev/sr0 is write-protected, mounting read-only

[root@study ~]# df /data/cdrom
Filesystem     1K-blocks    Used Available Use% Mounted on
/dev/sr0         7413478 7413478         0 100% /data/cdrom
# 怎么会使用掉 100% ？是啊！因为是 DVD 啊！所以无法再写入了！
```

**光驱一挂载之后就无法退出光盘片了！除非你将他卸载才能够退出**！从上面的数据你也可以发现，因为是光盘嘛！所以**磁盘使用率达到 100% ，因为你无法直接写入任何数据到光盘当中**！
此外，如果你**使用的是图形界面，那么系统会自动的帮你挂载这个光盘到`/media/`里面去！也可以不卸载就直接退出**！ 但是文字界面没有这个福利就是了。

#### 挂载 vfat 中文U盘 （USB磁盘）
```bash
范例：找出你的U盘设备的 UUID，并挂载到 /data/usb 目录中
[root@study ~]# blkid
/dev/sda1: UUID="35BC-6D6B" TYPE="vfat"

[root@study ~]# mkdir /data/usb
[root@study ~]#   mount -o codepage=950,iocharset=utf8 UUID="35BC-6D6B" /data/usb
[root@study ~]# # mount -o codepage=950,iocharset=big5 UUID="35BC-6D6B" /data/usb
[root@study ~]# df /data/usb
Filesystem     1K-blocks  Used Available Use% Mounted on
/dev/sda1        2092344     4   2092340   1% /data/usb
```

如果带有中文文件名的数据，那么可以在挂载时指定一下挂载文件系统所使用的语系数据。在 man mount 找到 vfat 文件格式当中可以使用 codepage 来处理！中文语系的代码为 950。

#### 重新挂载根目录与挂载不特定目录
目录树最重要的地方就是根目录了，所以根目录根本就不能够被卸载的！问题是，如果你的挂载参数要改变， 或者是根目录出现“只读”状态时，如何重新挂载：
```bash
范例：将 / 重新挂载，并加入参数为 rw 与 auto
[root@study ~]# mount -o remount,rw,auto /
```

#### umount （将设备文件卸载）
```bash
umount [-fn] 设备文件名或挂载点
选项与参数：
-f  ：强制卸载！可用在类似网络文件系统 （NFS） 无法读取到的情况下；
-l  ：立刻卸载文件系统，比 -f 还强！
-n  ：不更新 /etc/mtab 情况下卸载。
```

## 设置开机挂载
手动处理`mount`不是很人性化，我们需要让系统“自动”在开机时进行挂载，直接到`/etc/fstab`里面去修修就可以了。

### 开机挂载 /etc/fstab 及 /etc/mtab

系统挂载的一些限制：
- 根目录`/`是必须挂载的﹐而且一定要先于其它 mount point 被挂载进来。
- 其它 mount point 必须为已创建的目录﹐可任意指定﹐但一定要遵守必须的系统目录架构原则 （FHS）
- 所有 mount point 在同一时间之内﹐只能挂载一次。
- 所有 partition 在同一时间之内﹐只能挂载一次。
- 如若进行卸载﹐必须先将工作目录移到 mount point（及其子目录）之外。

`/etc/fstab`这个文件的内容:
```bash
[root@study ~]# cat /etc/fstab
# Device                              Mount point  filesystem parameters    dump fsck
/dev/mapper/centos-root                   /       xfs     defaults            0 0
UUID=94ac5f77-cb8a-495e-a65b-2ef7442b837c /boot   xfs     defaults            0 0
/dev/mapper/centos-home                   /home   xfs     defaults            0 0
/dev/mapper/centos-swap                   swap    swap    defaults            0 0
```

其实`/etc/fstab`（filesystem table）就是在我们利用`mount`指令进行挂载时，将所有的选项与参数写入到这个文件中。

## 内存交换空间（swap）
早期因为内存不足，因此那个**可以暂时将内存的程序拿到硬盘中暂放的内存交换空间（swap）就显的非常的重要**。否则，如果突然间某支程序用掉你大部分的内存，那你的系统恐怕有损毁的情况发生。

在安装 Linux 之前，大家常常会告诉你： 安装时一定需要的两个 partition ，一个是根目录，另外一个就是 swap（内存交换空间）。

一般来说，如果硬件的配备资源足够的话，那么 swap 应该不会被我们的系统所使用到， swap 会被利用到的时刻通常就是实体内存不足的情况了。

**我们知道 CPU 所读取的数据都来自于内存，那当内存不足的时候，为了让后续的程序可以顺利的运行，因此在内存中暂不使用的程序与数据就会被挪到 swap 中了。
此时内存就会空出来给需要执行的程序载入**。

虽然目前（2015）主机的内存都很大，至少都有 4GB 以上，不过对于服务，由于你不会知道何时会有大量来自网络的要求，因此最好还是能够预留一些 swap 来缓冲一下系统的内存用量。

### 使用实体分区创建swap
1. 分区：先使用 gdisk 在你的磁盘中分区出一个分区给系统作为 swap 。由于 Linux 的 gdisk 默认会将分区的 ID 设置为 Linux 的文件系统，所以你可能还得要设置一下 system ID 就是了。
2. 格式化：利用创建 swap 格式的“mkswap 设备文件名”就能够格式化该分区成为 swap 格式啰
3. 使用：最后将该 swap 设备启动，方法为：“swapon 设备文件名”。
4. 观察：最终通过 free 与 swapon -s 这个指令来观察一下内存的用量


## 压缩文件的用途与技术
什么是“文件压缩”？
我们使用的计算机系统中都是使用所谓的 Bytes 单位来计量的！不过，事实上，计算机最小的计量单位应该是 bits 才对啊。此外，我们也知道 1 Byte = 8 bits 。
如果今天我们只是记忆一个数字，亦即是 1 这个数字呢？他会如何记录？

由于我们记录数字是 1 ，考虑计算机所谓的二进制喔，如此一来，1 会在最右边占据1个 bit ，而其他的 7 个 bits 将会自动的被填上 0 ！那 7 个 bits 应该是“空的”才对！不过，为了要满足目前我们的操作系统数据的存取，
所以就会将该数据转为 Byte 的型态来记录了！而一些聪明的计算机工程师就利用一些复杂的计算方式， 将这些没有使用到的空间“丢”出来，以让文件占用的空间变小！这就是压缩的技术！

另外一种压缩技术也很有趣，他是将重复的数据进行统计记录的。举例来说，如果你的数据为“111....”共有100个1时， 那么压缩技术会记录为“100个1”而不是真的有100个1的位存在！这样也能够精简文
件记录的容量。

这个“压缩”与“解压缩”的动作有什么好处？最大的好处就是压缩过的文件大小变小了，所以你的硬盘容量无形之中就可以容纳更多的数据。此外，在一些网络数据的传输中，也会由于数据量的降低，
好让网络带宽可以用来作更多的工作！而不是老是卡在一些大型的文件传输上面！目前很多的 WWW 网站也是利用文件压缩的技术来进行数据的传送，好让网站带宽的可利用率上升。

## 常见的压缩指令
在Linux的环境中，压缩文件的扩展名大多是：“.tar, .tar.gz, .tgz, .gz, .Z, .bz2, *.xz”。
```bash
*.Z         compress 程序压缩的文件；
*.zip       zip 程序压缩的文件；
*.gz        gzip 程序压缩的文件；
*.bz2       bzip2 程序压缩的文件；
*.xz        xz 程序压缩的文件；
*.tar       tar 程序打包的数据，并没有压缩过；
*.tar.gz    tar 程序打包的文件，其中并且经过 gzip 的压缩
*.tar.bz2   tar 程序打包的文件，其中并且经过 bzip2 的压缩
*.tar.xz    tar 程序打包的文件，其中并且经过 xz 的压缩
```

**`tar`是一个打包指令，同时还可以通过 gzip/bzip2/xz 的支持，将该文件同时进行压缩**

## 什么是 Shell
操作系统其实是一组软件，由于这组软件在控制整个硬件与管理系统的活动监测，如果这组软件能被使用者随意的操作，若使用者应用不当，将会使得整个系统崩溃！因为操作系统管理的就是整个硬件功能。

但是我们总是需要让使用者操作系统的，所以就有了在操作系统上面发展的应用程序。使用者可以通过应用程序来指挥核心， 让核心达成我们所需要的硬件任务。我们可以发现应用程序其实是在最外层，
就如同鸡蛋的外壳一样，因此这个咚咚也就被称呼为壳程序（shell）。

shell的功能只是提供使用者操作系统的一个接口，因此shell 需要可以调用其他软件。例如man, chmod, chown, vi, fdisk, mkfs 等等指令，这些指令都是独立的应用程序。但是通过 shell可以操作
这些程序，让这些应用程序调用核心来运行所需的工作。常用的shell 有`bash`，`tcsh`等。

### bash shell 功能

- history
bash 能记忆使用过的指令。这么多的**指令记录在`~/.bash_history`。`~/.bash_history`记录的是前一次登陆以前所执行过的指令，至于这一次登陆所执行的指令都被暂存在内存中，当你成功的登出系统后，
该指令记忆才会记录到`.bash_history`当中**。

- 命令与文件补全
[tab] 按键。

- 命令别名
`alias lm='ls -al'`。

- shell scripts

### bash 的进站与欢迎讯息： /etc/issue, /etc/motd
bash 进站画面在`/etc/issue`里面。
```bash
[root@shcCDFrh75vm7 etc]# cat issue
\S
Kernel \r on an \m
```

- `\d`本地端时间的日期；
- `\l`显示第几个终端机接口；
- `\m`显示硬件的等级 （i386/i486/i586/i686...）；
- `\n`显示主机的网络名称；
- `\O`显示 domain name；
- `\r`操作系统的版本 （相当于 uname -r）
- `\t`显示本地端时间的时间；
- `\S`操作系统的名称；
- `\v`操作系统的版本。

`/etc/issue.net`是提供给 telnet 这个远端登陆程序用的。当我们使用 telnet 连接到主机时，主机的登陆画面就会显示`/etc/issue.net`而不是`/etc/issue`。

如果想要让使用者登陆后取得一些讯息，例如您想要让大家都知道的讯息，那么可以将讯息加入`/etc/motd`里面：
```bash
[root@study ~]# vim /etc/motd
Hello everyone,
Our server will be maintained at 2015/07/10 0:00 ~ 24:00.
Please don't login server at that time. ^_^
```

## 数据流重导向
1. 标准输入　　（stdin） ：代码为 0 ，使用`< 或`<<`
2. 标准输出　　（stdout）：代码为 1 ，使用`>`或`>>`
3. 标准错误输出（stderr）：代码为 2 ，使用`2>`或`2>>`

- `1>`：以覆盖的方法将“正确的数据”输出到指定的文件或设备上；
- `1>>`：以累加的方法将“正确的数据”输出到指定的文件或设备上；
- `2>`：以覆盖的方法将“错误的数据”输出到指定的文件或设备上；
- `2>>`：以累加的方法将“错误的数据”输出到指定的文件或设备上；

### /dev/null 垃圾桶黑洞设备与特殊写法
如果我知道错误讯息会发生，所以要将错误讯息忽略掉而不显示或储存，这个`/dev/null`可以吃掉任何导向这个设备的信息。

### 命令执行的判断依据：`;`,`&&`,`||`

#### `;`
```bash
cmd; cmd
```
在指令与指令中间利用分号`;`隔开，分号前的指令执行完后就会立刻接着执行后面的指令，但是指令之间没有相关性。

#### `$?`（指令回传值） 与`&&`或`||`
如果两个指令彼此之间是有相关性的，前一个指令是否成功的执行与后一个指令是否要执行有关，那就用到`&&`或`||`。

**指令回传值：若前一个指令执行的结果为正确，在 Linux 下面会回传一个`$? = 0`的值**。

- `cmd1 && cmd2`
  - 若 cmd1 执行完毕且正确执行（`$?=0`），则开始执行 cmd2。
  - 若 cmd1 执行完毕且为错误（`$?≠0`），则 cmd2 不执行。
- `cmd1 || cmd2`
  - 若 cmd1 执行完毕且正确执行（`$?=0`），则 cmd2 不执行。
  - 若 cmd1 执行完毕且为错误（`$?≠0`），则开始执行 cmd2。

例如`ls /tmp/vbirding && echo "exist" || echo "not exist"`，意思是说，当 ls /tmp/vbirding 执行后，若正确，就执行 echo "exist" ，若有问题，就执行 echo "not exist" 。

`ls /tmp/vbirding || echo "not exist" && echo "exist"`:
1. 若`ls /tmp/vbirding`不存在，因此回传一个非为 0 的数值；
2. 接下来经过`||`的判断，发现前一个指令回传非为 0 的数值，因此，程序开始执行`echo "not exist"`，而`echo "not exist"`程序肯定可以执行成功，因此会回传一个 0 值给后面的指令；
3. 经过`&&`的判断，咦！是 0 啊！所以就开始执行`echo "exist"`。

会同时出现`not exist`与`exist` 。

## pipe
管道命令`|`使用：
![](/images/linux-basic/bashpipe.png)

在每个`|`后面接的第一个数据必定是“指令”！而且这个指令必须要能够接受 standard input 的数据才行，这样的指令才可以是为管道指令，例如 less, more, head, tail 等都是可以
接受 standard input 的管道命令。例如 ls, cp, mv 等就不是管道命令了！因为 ls, cp, mv 并不会接受来自 stdin 的数据。

## Linux 的帐号与群组
### 使用者识别码： UID 与 GID
虽然我们登陆 Linux 主机的时候，输入的是我们的帐号，但是其实 Linux 主机并不会直接认识你的“帐号名称”的，他仅认识 ID。 由于计算机仅认识 0 与 1，所以主机对于数字比较有概念的；
至于帐号只是为了让人们容易记忆而已。而你的 ID 与帐号的对应就在`/etc/passwd`当中。

每个登陆的使用者至少都会取得两个 ID ，一个是使用者 ID （User ID ，简称 UID）、一个是群组 ID （Group ID ，简称 GID）。

文件如何判别他的拥有者与群组？其实就是利用 UID 与 GID！每一个文件都会有所谓的拥有者 ID 与拥有群组 ID ，当我们有要显示文件属性的需求时，系统会依据`/etc/passwd`与`/etc/group`的内容，
找到 UID/GID 对应的帐号与群组名称再显示出来。

登陆时，输入帐号密码后，系统帮你处理了什么？
1. 先找寻`/etc/passwd`里面是否有你输入的帐号？如果没有则跳出，如果有的话则将该帐号对应的 UID 与 GID（在`/etc/group`中） 读出来，另外，该帐号的主文件夹与 shell 设置也一并读出
2. 再来则是核对密码表啦！这时 Linux 会进入`/etc/shadow`里面找出对应的帐号与 UID，然后核对一下你刚刚输入的密码与里头的密码是否相符
3. 如果一切都 OK 的话，就进入 Shell 控管的阶段

由上面的流程我们知道，跟使用者帐号有关的有两个非常重要的文件，一个是管理使用者 UID/GID 重要参数的`/etc/passwd`，一个则是专门管理密码相关数据的`/etc/shadow`。

#### `/etc/passwd`文件结构
- 每一行都代表一个帐号。
- 里头很多帐号本来就是系统正常运行所必须要的，我们可以简称他为**系统帐号**。例如 bin, daemon, adm, nobody 等等。

```bash
[root@shcCDFrh75vm7 ~]# head -n 4 /etc/passwd
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
```

在每个Linux下第一行都是`root`，每一行使用`:`分隔，分为七个部分：
- 帐号名称：用来提供给对数字不太敏感的人类使用来登陆系统的！需要用来对应 UID。例如 root 的 UID 对应就是0（第三字段）；
- 密码：早期 Unix 系统的密码就是放在这字段上！但是因为这个文件的特性是所有的程序都能够读取，这样一来很容易造成密码数据被窃取，因此后来就将这个字段的密码数据给他改
放到`/etc/shadow`中了。所以这里你会看到一个`x`。
- UID： 这个就是使用者识别码
  - 当 UID 是 0 时，代表这个帐号是“系统管理员”！所以当你要让其他的帐号名称也具有 root 的权限时，将该帐号的 UID 改为 0 即可。这也就是说，一部系统上面的系统管理员不见得只有 root！
  不过，很不建议有多个帐号的 UID 是 0，容易让系统管理员混乱
  - UID 范围在1~999，那么就是保留给系统使用的 ID，其实除了 0 之外，其他的 UID 权限与特性并没有不一样。默认 1000 以下的数字让给系统作为保留帐号只是一个习惯。由于系统上面启动的网络服
  务或daemon服务希望使用较小的权限去运行，因此不希望使用 root 的身份去执行这些服务，所以我们就得要提供这些运行中程序的拥有者帐号才行。这些系统帐号通常是不可登陆的，根据系统帐号的由来，
  通常这类帐号又约略被区分为两种：1~200：由 distributions 自行创建的系统帐号；201~999：若使用者有系统帐号需求时，可以使用的帐号 UID。
  - UID 范围在1000~60000，给一般使用者用的。事实上，目前的 linux 核心 （3.10.x 版）已经可以支持到 4294967295 （2^32-1） 这么大的 UID 号码
- GID： 这个与`/etc/group`有关！其实`/etc/group`的观念与`/etc/passwd`差不多，只是他是用来规范群组名称与 GID 的对应而已
- 使用者信息说明栏： 这个字段基本上并没有什么重要用途，只是用来解释这个帐号的意义而已
- 主文件夹： 这是使用者的主文件夹，以上面为例， root 的主文件夹在`/root`，所以当 root 登陆之后，就会立刻跑到`/root`目录里头。默认的使用者主文件夹在`/home/yourIDname`。
- Shell：当使用者登陆系统后就会取得一个 Shell 来与系统的核心沟通以进行使用者的操作任务。就是在这个字段指定。

#### `/etc/shadow`文件结构
很多程序的运行都与权限有关，而权限与 UID/GID 有关！因此各程序当然需要读取`/etc/passwd`来了解不同帐号的权限。 因此`/etc/passwd`的权限需设置为`-rw-r--r--`这样的情况。
早期的密码也有加密过，但却放置到`/etc/passwd`的第二个字段上！这样一来很容易被有心人士所窃取的， 加密过的密码也能够通过暴力破解法去 trial and error （试误） 找出。

所以后来发展出将密码移动到`/etc/shadow`这个文件分隔开来的技术，而且还加入很多的密码限制参数在`/etc/shadow`里头。
```bash
[root@shcCDFrh75vm7 ~]# head -n 4 /etc/shadow
root:$6$PcVZ4yj4vlMjqmkL$RUHwggR7gPD0SnjTF1WnStHi2If0hSJnc4M/oVTfD0omJxVGhQgnQhBKRNPiwcBSeL72IerSphnEVdaomgjx./::0:99999:7:::
bin:*:17492:0:99999:7:::
daemon:*:17492:0:99999:7:::
adm:*:17492:0:99999:7:::
```

- 帐号名称
- 密码： 这个字段内的数据才是真正的密码，而且是经过编码的密码
- 最近更动密码的日期
- 密码不可被更动的天数：（与第 3 字段相比） 第四个字段记录了：这个帐号的密码在最近一次被更改后需要经过几天才可以再被变更。是 0 的话， 表示密码随时可以更动的意思。
- 密码需要重新变更的天数：（与第 3 字段相比） 经常变更密码是个好习惯！为了强制要求使用者变更密码，这个字段可以指定在最近一次更改密码后， 在多少天数内需要再次的变更密码才行。
- 密码需要变更期限前的警告天数：（与第 5 字段相比） 当帐号的密码有效期限快要到的时候 （第 5 字段），系统会依据这个字段的设置，发出“警告”言论给这个帐号。
- 密码过期后的帐号宽限时间（密码失效日）：（与第 5 字段相比） 密码有效日期为“更新日期（第3字段）”+“重新变更日期（第5字段）”，过了该期限后使用者依旧没有更新密码，那该密码就算过期了。
- 帐号失效日期： 这个日期跟第三个字段一样，都是使用 1970 年以来的总日数设置。这个字段表示： 这个帐号在此字段规定的日期之后，将无法再使用。
- 保留： 最后一个字段是保留的，看以后有没有新功能加入。

#### `/etc/group`文件结构
这个文件记录 GID 与群组名称的对应。
```bash
[root@study ~]# head -n 4 /etc/group
root:x:0:
bin:x:1:
daemon:x:2:
sys:x:3:
```

- 群组名称。
- 群组密码：通常不需要设置，这个设置通常是给“群组管理员”使用的，目前很少有这个机会设置群组管理员！同样的，密码已经移动到`/etc/gshadow`去，因此这个字段只会存在一个`x`
- GID：就是群组的 ID。我们`/etc/passwd`第四个字段使用的 GID 对应的群组名，就是由这里对应出来的！
- 此群组支持的帐号名称：我们知道一个帐号可以加入多个群组，那某个帐号想要加入此群组时，将该帐号填入这个字段即可。举例来说，如果我想要让 dmtsai 与 alex 也加入 root 这个群组，
那么在第一行的最后面加上“dmtsai,alex”，注意不要有空格，使成为“ root:x:0:dmtsai,alex ”就可以。

#### 有效群组（effective group）与初始群组（initial group）

每个使用者在他的 /etc/passwd 里面的第四栏有GID，那个 GID 就是所谓的“初始群组（initial group）。当使用者一登陆系统，立刻就拥有这个群组的相关权限的意思。
因为是初始群组， 使用者一登陆就会主动取得，不需要在`/etc/group`的第四个字段写入该帐号的。

但是非 initial group 的其他群组可就不同了。举上面这个例子来说，我将 dmtsai 加入 users 这个群组当中，由于 users 这个群组并非是 dmtsai 的初始群组，因此，
我必须要在`/etc/group`这个文件中，找到 users 那一行，并且将 dmtsai 这个帐号加入第四栏， 这样 dmtsai 才能够加入 users 这个群组。

如何知道我所有支持的群组？：
```bash
[dmtsai@study ~]$ groups
dmtsai wheel users
```
可知道当前用户同时属于 dmtsai, wheel 及 users 这三个群组，一个输出的群组即为有效群组（effective group）了。

如果创建一个新的文件或者是新的目录，新文件的群组是当时的有效群组了（effective group）。

## 帐号管理
### 新增与移除使用者
创建一个可用的帐号需要帐号与密码。那帐号可以使用`useradd`来新建使用者，密码的给予则使用`passwd`这个指令：
```bash
useradd [-u UID] [-g 初始群组] [-G 次要群组] [-mM] [-c 说明栏] [-d 主文件夹绝对路径] [-s shell] 使用者帐号名
选项与参数：
-u  ：后面接的是 UID ，是一组数字。直接指定一个特定的 UID 给这个帐号
-g  ：后面接的那个群组名称就是我们上面提到的 initial group
      该群组的 GID 会被放置到 /etc/passwd 的第四个字段内。
-G  ：后面接的群组名称则是这个帐号还可以加入的群组。
      这个选项与参数会修改 /etc/group 内的相关数据！
-M  ：强制！不要创建使用者主文件夹！（系统帐号默认值）
-m  ：强制！要创建使用者主文件夹！（一般帐号默认值）
-c  ：这个就是 /etc/passwd 的第五栏的说明内容
-d  ：指定某个目录成为主文件夹，而不要使用默认值。务必使用绝对路径！
-r  ：创建一个系统的帐号，这个帐号的 UID 会有限制
-s  ：后面接一个 shell ，若没有指定则默认是 /bin/bash 的啦～
-e  ：后面接一个日期，格式为“YYYY-MM-DD”此项目可写入 shadow 第八字段，亦即帐号失效日的设置项目
-f  ：后面接 shadow 的第七字段项目，指定密码是否会失效。0为立刻失效，-1 为永远不失效（密码只会过期而强制于登陆时重新设置而已。）
```

还需要使用`passwd 帐号`来给予密码才算是完成了使用者创建的流程。
```bash
# 修改帐号密码
passwd [--stdin] [帐号名称]

#
passwd [-l] [-u] [--stdin] [-S] [-n 日数] [-x 日数] [-w 日数] [-i 日期] 帐号
选项与参数：
--stdin ：可以通过来自前一个管线的数据，作为密码输入，对 shell script 有帮助！
-l  ：是 Lock 的意思，会将 /etc/shadow 第二栏最前面加上 ! 使密码失效；
-u  ：与 -l 相对，是 Unlock 的意思！
-S  ：列出密码相关参数，亦即 shadow 文件内的大部分信息。
-n  ：后面接天数，shadow 的第 4 字段，多久不可修改密码天数
-x  ：后面接天数，shadow 的第 5 字段，多久内必须要更动密码
-w  ：后面接天数，shadow 的第 6 字段，密码过期前的警告天数
-i  ：后面接“日期”，shadow 的第 7 字段，密码失效日期
```

**注意使用`passwd`后面没有帐号，表示修改自己的密码。尤其是root帐号。**

#### useradd 参考档
为何`useradd vbird1`会主动在`/home/vbird1`创建起使用者的主文件夹？主文件夹内有什么数据且来自哪里？为何默认使用的是`/bin/bash`这个`shell`？

useradd 的默认值可以使用下面的方法调用出来:
```bash
[root@study ~]# useradd -D
GROUP=100        #默认的群组
HOME=/home        #默认的主文件夹所在目录
INACTIVE=-1        #密码失效日，在 shadow 内的第 7 栏
EXPIRE=            #帐号失效日，在 shadow 内的第 8 栏
SHELL=/bin/bash        #默认的 shell
SKEL=/etc/skel        #使用者主文件夹的内容数据参考目录
CREATE_MAIL_SPOOL=yes   #是否主动帮使用者创建邮件信箱（mailbox）
```

#### usermod
`usermod`用于修改帐号的相关数据。
```bash
[root@study ~]# usermod [-cdegGlsuLU] username
选项与参数：
-c  ：后面接帐号的说明，即 /etc/passwd 第五栏的说明栏，可以加入一些帐号的说明。
-d  ：后面接帐号的主文件夹，即修改 /etc/passwd 的第六栏；
-e  ：后面接日期，格式是 YYYY-MM-DD 也就是在 /etc/shadow 内的第八个字段数据啦！
-f  ：后面接天数，为 shadow 的第七字段。
-g  ：后面接初始群组，修改 /etc/passwd 的第四个字段，亦即是 GID 的字段！
-G  ：后面接次要群组，修改这个使用者能够支持的群组，修改的是 /etc/group 啰～
-a  ：与 -G 合用，可“增加次要群组的支持”而非“设置”喔！
-l  ：后面接帐号名称。亦即是修改帐号名称， /etc/passwd 的第一栏！
-s  ：后面接 Shell 的实际文件，例如 /bin/bash 或 /bin/csh 等等。
-u  ：后面接 UID 数字啦！即 /etc/passwd 第三栏的数据；
-L  ：暂时将使用者的密码冻结，让他无法登陆。其实仅改 /etc/shadow 的密码栏。
-U  ：将 /etc/shadow 密码栏的 ! 拿掉，解冻
```

usermod 的选项与 useradd 非常类似！ 这是因为 usermod 也是用来微调 useradd 增加的使用者参数。

#### userdel
```bash
userdel [-r] username
选项与参数：
-r  ：连同使用者的主文件夹也一起删除
```


#### id
`id`这个指令则可以查询某人或自己的相关 UID/GID 等等的信息。
```bash
id [username]
```

### 新增与移除群组
#### groupadd
```bash
[root@study ~]# groupadd [-g gid] [-r] 群组名称
选项与参数：
-g  ：后面接某个特定的 GID ，用来直接给予某个 GID ～
-r  ：创建系统群组！与 /etc/login.defs 内的 GID_MIN 有关。
```

#### groupmod
修改group 相关参数。
```bash
[root@study ~]# groupmod [-g gid] [-n group_name] 群组名
选项与参数：
-g  ：修改既有的 GID 数字；
-n  ：修改既有的群组名称
```

**如果要删除某个group，必须要确认`/etc/passwd`内的帐号没有任何人使用该群组作为 initial group**，否则无法删除。但是可以通过下面的范式删除：
- 修改这个group的 GID
- 删除使用这个群组为initial group 的这个使用者

#### gpasswd 群组管理员功能
gpasswd创建一个群组管理员，让某个群组具有一个管理员，这个群组管理员可以管理哪些帐号可以加入/移出该群组。
```bash
# 关于系统管理员（root）做的动作：
[root@study ~]# gpasswd groupname
[root@study ~]# gpasswd [-A user1,...] [-M user3,...] groupname
[root@study ~]# gpasswd [-rR] groupname
选项与参数：
    ：若没有任何参数时，表示给予 groupname 一个密码（/etc/gshadow）
-A  ：将 groupname 的主控权交由后面的使用者管理（该群组的管理员）
-M  ：将某些帐号加入这个群组当中！
-r  ：将 groupname 的密码移除
-R  ：让 groupname 的密码栏失效

# 关于群组管理员（Group administrator）做的动作：
[someone@study ~]$ gpasswd [-ad] user groupname
选项与参数：
-a  ：将某位使用者加入到 groupname 这个群组当中！
-d  ：将某位使用者移除出 groupname 这个群组当中。
```

## 主机的细部权限规划：ACL 的使用
Linux 的权限概念非常重要， 但是传统的权限仅有三种身份 （owner, group, others） 搭配三种权限 （r,w,x） 而已，
并没有办法单纯的针对某一个使用者或某一个群组来设置特定的权限需求，此时就得要使用 ACL 这个机制。

**ACL 是 Access Control List 的缩写，主要的目的是在提供传统的 owner,group,others 的 read,write,execute 权限之外的细部权限设置。**ACL
可以针对单一使用者，单一文件或目录来进行 r,w,x 的权限规范，对于需要特殊权限的使用状况非常有帮助。

ACL 几乎已经默认加入在所有常见的 Linux 文件系统的挂载参数中。

### ACL 的设置：getfacl, setfacl
- getfacl：取得某个文件/目录的 ACL 设置项目；
- setfacl：设置某个目录/文件的 ACL 规范。

## 使用者身份切换
- 使用一般帐号：系统平日操作的好习惯。尽量以一般身份使用者来操作 Linux，等到需要设置系统环境时，才变换身份成为 root 来进行系统管理。
- 用较低权限启动系统服务，例如apache，可以创建一个名为 apache 的使用者来启动 apache 软件，如此一来，如果这个程序被攻破，至少系统还不至于就损毁了。

### 使用者身份切换的两种方式
- `su`命令
- `sudo cmd`

#### su
```bash
[root@study ~]# su [-lm] [-c 指令] [username]
选项与参数：
-   ：单纯使用 - 如“ su - ”代表使用 login-shell 的变量文件读取方式来登陆系统；
      若使用者名称没有加上去，则代表切换为 root 的身份。
-l  ：与 - 类似，但后面需要加欲切换的使用者帐号！也是 login-shell 的方式。
-m  ：-m 与 -p 是一样的，表示“使用目前的环境设置，而不读取新使用者的配置文件”
-c  ：仅进行一次指令，所以 -c 后面可以加上指令喔
```

`su`的用法是这样的：
- 要完整的切换到新使用者的环境，必须要使用“ su - username ”或“ su -l username ”， 才会连同 PATH/USER/MAIL 等变量都转成新使用者的环境；
- 如果仅想要执行一次 root 的指令，可以利用`su - -c cmd`的方式来处理；
- 使用 root 切换成为任何使用者时，并不需要输入新使用者的密码；

#### sudo
su 需要了解新切换的使用者密码（常常是需要 root 的密码）， sudo 的执行则仅需要自己的密码。**仅有规范到`/etc/sudoers`内的用户才能够执行 sudo 这个指令**。
除非是信任用户，否则一般用户默认是不能操作 sudo 的。
```bash
[root@study ~]# sudo [-b] [-u 新使用者帐号]
选项与参数：
-b  ：将后续的指令放到背景中让系统自行执行，而不与目前的 shell 产生影响
-u  ：后面可以接欲切换的使用者，若无此项则代表切换身份为 root 。
```

sudo 默认仅有 root 能使用，因为 sudo 的执行是这样的流程：
1. 当使用者执行 sudo 时，系统于`/etc/sudoers`文件中搜寻该使用者是否有执行 sudo 的权限；
2. 若使用者具有可执行 sudo 的权限后，便让使用者“输入使用者自己的密码”来确认；
3. 若密码输入成功，便开始进行 sudo 后续接的指令（但 root 执行 sudo 时，不需要输入密码）；
4. 若欲切换的身份与执行者身份相同，那也不需要输入密码。

#### visudo 与`/etc/sudoers`
除了 root 之外的其他帐号，若想要使用 sudo 执行属于 root 的权限指令，则 root 需要先使用 visudo 去修改`/etc/sudoers`，
**`/etc/sudoers`是有设置语法的，如果设置错误那会造成无法使用 sudo 指令的不良后果。因此才会使用 visudo 去修改**。


## `/sbin/nologin`与 PAM 模块
`passwd`文件结构里面我们就谈过系统帐号，系统帐号的shell 就是使用`/sbin/nologin`。系统帐号是不需要登陆的，所以我们就给他这个无法登陆的合法 shell。
使用了这个 shell 的用户即使有了密码，你想要登陆时他也无法登陆，因为会出现如下的讯息：
```bash
This account is currently not available.
```
“无法登陆”指的仅是：“这个使用者无法使用 bash 或其他 shell 来登陆系统”。

### PAM 模块
之前谈到过`/etc/login.defs`文件中，关于密码长度应该默认是 5 个字串长度，但是该设置值已经被 PAM 模块所取代了，那么 PAM 是什么？

在过去，我们想要对一个使用者进行认证 （authentication），得要要求使用者输入帐号密码， 然后通过自行撰写的程序来判断该帐号密码是否正确。也因为如此，
我们常常得使用不同的机制来判断帐号密码， 所以搞的一部主机上面拥有多个各别的认证系统，也造成帐号密码可能不同步的验证问题。

为了解决这个问题因此有了 PAM （Pluggable Authentication Modules, 嵌入式模块） 的机制。
PAM 仅是一套验证的机制，又可以提供给其他程序所调用引用，因此不论你使用什么程序，都可以使用 PAM 来进行验证，如此一来，就能够让帐号密码或者是其他方式的验证具有一致的结果。

PAM 是一个独立的 API 存在，只要任何程序有需求时，可以向 PAM 发出验证要求的通知， PAM 经过一连串的验证后，将验证的结果回报给该程序，然后该程序就能够利用验证的结果来进行
可登陆或显示其他无法使用的讯息。

#### PAM 模块设置语法
以 passwd 这个指令的调用 PAM 来说明，当你执行 passwd 后，这支程序调用 PAM 的流程是：
1. 使用者开始执行`/usr/bin/passwd`这支程序，并输入密码；
2. passwd 调用 PAM 模块进行验证；
3. PAM 模块会到`/etc/pam.d/`找寻与程序 （passwd） 同名的配置文件；
4. 依据`/etc/pam.d/passwd`内的设置，引用相关的 PAM 模块逐步进行验证分析；
5. 将验证结果 （成功、失败以及其他讯息） 回传给 passwd 这支程序；
6. passwd 这支程序会根据 PAM 回传的结果决定下一个动作 （重新输入新密码或者通过验证）

重点其实是`/etc/pam.d/`里面的配置文件，以及配置文件所调用的 PAM 模块进行的验证工作。
```bash
[root@study ~]# cat /etc/pam.d/passwd
#PAM-1.0  => PAM版本的说明而已！
auth       include      system-auth   => 每一行都是一个验证的过程
account    include      system-auth
password   substack     system-auth
-password   optional    pam_gnome_keyring.so use_authtok
password   substack     postlogin
验证类别   控制标准     PAM 模块与该模块的参数
```

`include`这个关键字，他代表的是“请调用后面的文件来作为这个类别的验证”， 所以，上述的每一行都要重复调用`/etc/pam.d/system-auth`那个文件来进行验证的意思。

##### 第一个字段：验证类别 （Type）
验证类别主要分为四种:
- auth，主要用来检验使用者的身份验证，这种类别通常是需要密码来检验的， 所以后续接的模块是用来检验使用者的身份。
- account，大部分是在进行 authorization （授权），这种类别则主要在检验使用者是否具有正确的使用权限， 举例来说，当你使用一个过期的密码来登陆时，当然就无法正确的登陆了。
- session，管理的就是使用者在这次登陆 （或使用这个指令） 期间，PAM 所给予的环境设置。 这个类别通常用在记录使用者登陆与登出时的信息。
- password，主要在提供验证的修订工作，举例来说，就是修改/变更密码。

**四个验证的类型通常是有顺序的**，不过也有例外就是了。 会有顺序的原因是，（1）我们总是得要先验证身份 （auth） 后， （2）系统才能够借由使用者的身份给予适当的授权与权限设置 （account），
而且（3）登陆与登出期间的环境才需要设置， 也才需要记录登陆与登出的信息 （session）。如果在运行期间需要密码修订时，（4）才给予 password 的类别。


##### 第二个字段：验证的控制旗标 （control flag）
就是“验证通过的标准”。四种控制方式：
- required，此验证若成功则带有 success （成功） 的标志，若失败则带有 failure 的标志，但不论成功或失败都会继续后续的验证流程。 由于后续的验证流程可以继续进行，
因此相当有利于数据的登录。
- requisite，验证失败则立刻回报原程序 failure 的标志，并终止后续的验证流程。验证成功则带有 success 的标志并继续后续的验证流程。
- sufficient，验证成功则立刻回传 success 给原程序，并终止后续的验证流程；若验证失败则带有 failure 标志并继续后续的验证流程。 这玩意儿与 requisits 刚好相反。
- optional，控制项目大多是在显示讯息而已，并不是用在验证方面的。

## Linux 主机上的使用者讯息
### 查询使用者： w, who, last, lastlog
- `id`，了解到一个使用者的相关信息
- `last`，CentOS 5.x 版以后， last 可以列出从系统创建之后到目前为止的所有登陆者信息。
- `w`或者`who`，查询当前登陆在系统上面的使用者
- `lastlog`，查询每个帐号的最近登陆的时间，lastlog 会去读取`/var/log/lastlog`文件，结果将数据输出

### 使用者对谈：write, mesg, wall
是否可以跟系统上面的使用者谈天说地？利用 write 这个指令即可。 write 可以直接将讯息传给接收者。例如：我们的 Linux 目前有 vbird1 与 root 两个人在线上，
root 要跟 vbird1 讲话，可以这样做：
```bash
[root@study ~]# write 使用者帐号 [使用者所在终端接口]

[root@study ~]# who
vbird1   tty3         2015-07-22 01:55  <==有看到 vbird1 在线上
root     tty4         2015-07-22 01:56

[root@study ~]# write vbird1 pts/2
Hello, there:
Please don't do anything wrong...  <==这两行是 root 写的信息！
# 结束时，请按下 [crtl]-d 来结束输入。此时在 vbird1 的画面中，会出现：

Message from root@study.centos.vbird on tty4 at 01:57 ...
Hello, there:
Please don't do anything wrong...
EOF
```

`mesg`不接受消息，但是root的消息还是会接收。

## 磁盘配额 （Quota）
在 Linux 系统中，由于是多用户多任务的环境，所以会有多人共同使用一个硬盘空间的情况发生， 如果其中有少数几个使用者大量的占掉了硬盘空间的话，那势必压缩其他使用者的使用权力。
因此管理员应该适当的限制硬盘的容量给使用者，以妥善的分配系统资源。


### Quota 的一般用途
比较常使用的几个情况是：
- 针对 WWW server ，例如：每个人的网页空间的容量限制
- 针对 mail server，例如：每个人的邮件空间限制。
- 限制某一群组所能使用的最大磁盘配额 （使用群组限制）
- 限制某一使用者的最大磁盘配额
- 限制某一目录 （directory, project） 的最大磁盘配额

## 例行性工作调度
### Linux 工作调度的种类： at, crontab
工作调度的方式：
- 一种是例行性的，就是每隔一定的周期要来办的事项
- 一种是突发性的，就是这次做完以后就没有的那一种

- at：at 是个可以处理仅执行一次就结束调度的指令，不过要执行 at 时， 必须要有 atd 这个服务的支持才行，atd 在CentOS 默认是启动。
- crontab ：crontab 这个指令所设置的工作将会循环的一直进行下去。

#### atd 的启动与 at 运行的方式
```bash
[root@study ~]# systemctl restart atd  # 重新启动 atd 这个服务
[root@study ~]# systemctl enable atd   # 让这个服务开机就自动启动
[root@study ~]# systemctl status atd   # 查阅一下 atd 目前的状态
```

##### at
```bash
[root@study ~]# at [-mldv] TIME
[root@study ~]# at -c 工作号码
选项与参数：
-m  ：当 at 的工作完成后，即使没有输出讯息，亦以 email 通知使用者该工作已完成。
-l  ：at -l 相当于 atq，列出目前系统上面的所有该使用者的 at 调度；
-d  ：at -d 相当于 atrm ，可以取消一个在 at 调度中的工作；
-v  ：可以使用较明显的时间格式列出 at 调度中的工作列表；
-c  ：可以列出后面接的该项工作的实际指令内容。
```

并不是所有的人都可以进行 at 工作调度。
利用`/etc/at.allow`与`/etc/at.deny`这两个文件来进行 at 的使用限制，at 的工作情况其实是这样的：
1. 先找寻`/etc/at.allow`这个文件，写在这个文件中的使用者才能使用 at ，没有在这个文件中的使用者则不能使用 at （即使没有写在`at.deny`当中）
2. 如果`/etc/at.allow`不存在，就寻找`/etc/at.deny`这个文件，若写在这个`at.deny`的使用者则不能使用 at ，而没有在这个`at.deny`文件中的使用者，就可以使用 at。
3. 如果两个文件都不存在，那么只有 root 可以使用 at 这个指令

利用`atq`来查询，利用`atrm`来删除错误的指令。

##### batch
 batch 是利用 at 来进行指令的下达。他会在 CPU 的工作负载小于 0.8 的时候，才进行你所下达的工作任务。

#### crontab
限制使用 crontab 的使用者帐号：
- `/etc/cron.allow`：将可以使用 crontab 的帐号写入其中，若不在这个文件内的使用者则不可使用 crontab
- `/etc/cron.deny`：将不可以使用 crontab 的帐号写入其中，若未记录到这个文件当中的使用者，就可以使用 crontab。

`/etc/cron.allow`比`/etc/cron.deny`要优先， 而判断上面，这两个文件只选择一个来限制而已，因此，建议你只要保留一个即可。
一般来说，系统默认是保留`/etc/cron.deny`。

```bash
[root@study ~]# crontab [-u username] [-l|-e|-r]
选项与参数：
-u  ：只有 root 才能进行这个任务，亦即帮其他使用者创建/移除 crontab 工作调度；
-e  ：编辑 crontab 的工作内容
-l  ：查阅 crontab 的工作内容
-r  ：移除所有的 crontab 的工作内容，若仅要移除一项，请用 -e 去编辑。
```

#####  一些注意事项
以系统的 cron 来进行例行性工作的创建时，要注意一些使用方面的特性。 举例来说，如果我们有四个工作都是五分钟要进行一次的，那么是否这四个动作全部都在同一个时间点进行？
如果同时进行，该四个动作又很耗系统资源，如此一来，每五分钟的某个时刻不是会让系统忙得要死？所以要注意：
- 资源分配不均的问题
  - 流量
  - 区域内其他 PC 的流量侦测
  - CPU 使用率
  - RAM 使用率
  - 线上人数实时侦测

如果每个流程都在同一个时间启动的话，那么在某个时段时，我的系统会变的相当的繁忙，所以，这个时候就必须要分别设置！可以这样做：
```bash
[root@study ~]# vim /etc/crontab
1,6,11,16,21,26,31,36,41,46,51,56 * * * * root  CMD1
2,7,12,17,22,27,32,37,42,47,52,57 * * * * root  CMD2
3,8,13,18,23,28,33,38,43,48,53,58 * * * * root  CMD3
4,9,14,19,24,29,34,39,44,49,54,59 * * * * root  CMD4
```
**那个`,`分隔的时候，请注意，不要有空白字符**。如此一来， 则可以将每五分钟工作的流程分别在不同的时刻来工作。

- 取消不要的输出项目
- 安全的检验
- 周与日月不可同时并存

## 程序管理
一个程序被载入到内存当中运行，那么在内存内的那个数据就被称为程序（process）。

program：通常为 binary program ，放置在储存媒体中 （如硬盘、光盘、软盘、磁带等）， 为实体文件的型态存在；
process：程序被触发后，执行者的权限与属性、程序的程序码与所需数据等都会被载入内存中， 操作系统并给予这个内存内的单元一个识别码 （PID），可以说，程序就是一个正在运行中的程序。

### 父子进程
比如 打开一个bash的shell，这是一个进程，然后又执行了一个touch命令，这个touch命令就是子进程。每个进程有一个pid，ppid他的父进程的pid。

### 进程管理
#### 后台运行进程`&`
在指令的最后面加上一个`&`代表将该指令丢到后台运行。

#### 查看后台运行的进程
```bash
[root@study ~]# jobs [-lrs]
选项与参数：
-l  ：除了列出 job number 与指令串之外，同时列出 PID 的号码；
-r  ：仅列出正在背景 run 的工作；
-s  ：仅列出正在背景当中暂停 （stop） 的工作。
```

#### 把后台运行的进程拿到前台`fg`
```bash
[root@study ~]# fg %jobnumber
选项与参数：
%jobnumber ：jobnumber 为工作号码（数字）。注意，那个 % 是可有可无的
```

#### `kill`杀死进程
```bash
[root@study ~]# kill -signal %jobnumber
[root@study ~]# kill -l
选项与参数：
-l  ：这个是 L 的小写，列出目前 kill 能够使用的讯号 （signal） 有哪些？
signal ：代表给予后面接的那个工作什么样的指示啰！用 man 7 signal 可知：
  -1 ：重新读取一次参数的配置文件 （类似 reload）；
  -2 ：代表与由键盘输入 [ctrl]-c 同样的动作；
  -9 ：立刻强制删除一个工作；
  -15：以正常的程序方式终止一项工作。与 -9 是不一样的。
```
#### 离线管理
```bash
[root@study ~]# nohup [指令与参数]
[root@study ~]# nohup [指令与参数] &
```

#### 查看进程
##### ps
```bash
[root@study ~]# ps aux  观察系统所有的程序数据
[root@study ~]# ps -lA  也是能够观察所有系统的数据
[root@study ~]# ps axjf 连同部分程序树状态
选项与参数：
-A  ：所有的 process 均显示出来，与 -e 具有同样的效用；
-a  ：不与 terminal 有关的所有 process ；
-u  ：有效使用者 （effective user） 相关的 process ；
x   ：通常与 a 这个参数一起使用，可列出较完整信息。
输出格式规划：
l   ：较长、较详细的将该 PID 的的信息列出；
j   ：工作的格式 （jobs format）
-f  ：做一个更为完整的输出。
```

##### ps -l
仅观察自己的 bash 相关进程。
```bash
[root@study ~]# ps -l
F S   UID   PID  PPID  C PRI  NI ADDR SZ WCHAN  TTY          TIME CMD
4 S     0 14830 13970  0  80   0 - 52686 poll_s pts/0    00:00:00 sudo
4 S     0 14835 14830  0  80   0 - 50511 wait   pts/0    00:00:00 su
4 S     0 14836 14835  0  80   0 - 29035 wait   pts/0    00:00:00 bash
0 R     0 15011 14836  0  80   0 - 30319 -      pts/0    00:00:00 ps
```

- F：代表这个 process flags，说明这个程序的总结权限，常见号码有：
  - 若为 4 表示此进程的权限为 root ；
  - 若为 1 则表示此子进程仅进行复制（fork）而没有实际执行（exec）。
- S：代表这个进程的状态 （STAT），主要的状态有：
  - R （Running）：正在运行中；
  - S （Sleep）：目前正在睡眠状态（idle），但可以被唤醒（signal）。
  - D ：不可被唤醒的睡眠状态，通常这支进程可能在等待 I/O 的情况（ex>打印）
  - T ：停止状态（stop），可能是在工作控制（后台暂停）或除错 （traced） 状态；
  - Z （Zombie）：僵尸状态，进程已经终止但却无法被移除至内存外。
- UID/PID/PPID：代表“此进程被该 UID 所拥有/进程的 PID 号码/此进程的父进程 PID 号码”
- C：代表 CPU 使用率，单位为百分比；
- PRI/NI：Priority/Nice 的缩写，代表此进程被 CPU 所执行的优先顺序，数值越小代表该进程越快被 CPU 执行。
- ADDR/SZ/WCHAN：都与内存有关，ADDR 是 kernel function，指出该进程在内存的哪个部分，如果是个 running 的进程，
一般就会显示`-`/ SZ 代表此进程用掉多少内存 / WCHAN 表示目前进程是否运行中，同样的，若为`-`表示正在运行中。
- TTY：登陆者的终端机位置，若为远端登陆则使用动态终端接口 （pts/n）；
- TIME：使用掉的 CPU 时间，注意，是此进程实际花费 CPU 运行的时间，而不是系统时间；
- CMD：就是 command 的缩写，造成此进程的触发程序的指令是什么。

##### ps aux
列出目前所有的正在内存当中的程序。
```bash
[root@study ~]# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.2  60636  7948 ?        Ss   Aug04   0:01 /usr/lib/systemd/systemd ...
root         2  0.0  0.0      0     0 ?        S    Aug04   0:00 [kthreadd]
.....（中间省略）.....
root     14830  0.0  0.1 210744  3988 pts/0    S    Aug04   0:00 sudo su -
root     14835  0.0  0.1 202044  2996 pts/0    S    Aug04   0:00 su -
root     14836  0.0  0.1 116140  2960 pts/0    S    Aug04   0:00 -bash
.....（中间省略）.....
root     18459  0.0  0.0 123372  1380 pts/0    R+   00:25   0:00 ps aux
```

- USER：该 process 属于那个使用者帐号的？
- PID ：该 process 的程序识别码。
- %CPU：该 process 使用掉的 CPU 资源百分比；
- %MEM：该 process 所占用的实体内存百分比；
- VSZ ：该 process 使用掉的虚拟内存量 （KBytes）
- RSS ：该 process 占用的固定的内存量 （KBytes）
- TTY ：该 process 是在那个终端机上面运行，若与终端机无关则显示 ?，另外， tty1-tty6 是本机上面的登陆者程序，若为 pts/0 等等的，则表示为由网络连接进主机的程序。
- STAT：该程序目前的状态，状态显示与 ps -l 的 S 旗标相同 （R/S/T/Z）
- START：该 process 被触发启动的时间；
- TIME ：该 process 实际使用 CPU 运行的时间。
- COMMAND：该程序的实际指令为何？


##### `ps axjf`和`ps -lA`
- `ps -lA`，显示出所有的程序，与 ps -l 的输出情况相同。
- `ps axjf`，列出类似进程树的进程显示

##### top 动态观察进程的变化
相对于`ps`是获取一个时间点的进程状态，`top`则可以持续侦测进程运行的状态：
```bash
[root@study ~]# top [-d 数字] | top [-bnp]
选项与参数：
-d  ：后面可以接秒数，就是整个程序画面更新的秒数。默认是 5 秒；
-b  ：以批次的方式执行 top,通常会搭配数据流重导向来将批次的结果输出成为文件。
-n  ：与 -b 搭配，意义是，需要进行几次 top 的输出结果。
-p  ：指定某些个 PID 来进行观察监测而已。
在 top 执行过程当中可以使用的按键指令：
    ? ：显示在 top 当中可以输入的按键指令；
    P ：以 CPU 的使用资源排序显示；
    M ：以 Memory 的使用资源排序显示；
    N ：以 PID 来排序;
    T ：由该 Process 使用的 CPU 时间累积 （TIME+） 排序。
    k ：给予某个 PID 一个讯号  （signal）
    r ：给予某个 PID 重新制订一个 nice 值。
    q ：离开 top 软件的按键。

# 每两秒钟更新一次 top
[root@study ~]# top -d 2
[root@study ~]# top -d 2
top - 00:53:59 up  6:07,  3 users,  load average: 0.00, 0.01, 0.05
Tasks: 179 total,   2 running, 177 sleeping,   0 stopped,   0 zombie
%Cpu（s）:  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :  2916388 total,  1839140 free,   353712 used,   723536 buff/cache
KiB Swap:  1048572 total,  1048572 free,        0 used.  2318680 avail Mem

 PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
18804 root      20   0  130028   1872   1276 R   0.5  0.1   0:00.02 top
    1 root      20   0   60636   7948   2656 S   0.0  0.3   0:01.70 systemd
    2 root      20   0       0      0      0 S   0.0  0.0   0:00.01 kthreadd
    3 root      20   0       0      0      0 S   0.0  0.0   0:00.00 ksoftirqd/0
```

- 第一行（top...）：这一行显示的信息分别为：
  - 目前的时间，亦即是 00:53:59 那个项目；
  - 开机到目前为止所经过的时间，亦即是 up 6:07, 那个项目；
  - 已经登陆系统的使用者人数，亦即是 3 users, 项目；
  - 系统在 1, 5, 15 分钟的平均工作负载。代表的是 1, 5, 15 分钟，系统平均要负责运行几个程序（工作）的意思。 越小代表系统越闲置，若高于 1 得要注意你的系统程序是否太过繁复了！
- 第二行（Tasks...）：显示的是目前进程的总量与个别进程在什么状态（running, sleeping, stopped, zombie）。 比较需要注意的是最后的 zombie 那个数值，如果不是 0,
好好看看到底是那个 process 变成僵尸了
- 第三行（%Cpus...）：显示的是 CPU 的整体负载，每个项目可使用`?`查阅。需要特别注意的是 wa ，代表的是 I/O wait， 通常你的系统会变慢都是 I/O 产生的问题比较大！
因此这里得要注意这个项目耗用 CPU 的资源. 另外，如果是多核心的设备，可以按下数字键“1”来切换成不同 CPU 的负载率。
- 第四行与第五行：表示目前的实体内存与虚拟内存 （Mem/Swap） 的使用情况。**如果 swap 被用的很大量，表示系统的实体内存实在不足**

##### pstree
```bash
[root@study ~]# pstree [-A|U] [-up]
选项与参数：
-A  ：各程序树之间的连接以 ASCII 字符来连接；
-U  ：各程序树之间的连接以万国码的字符来连接。在某些终端接口下可能会有错误；
-p  ：并同时列出每个 process 的 PID；
-u  ：并同时列出每个 process 的所属帐号名称。
```

#### 进程的执行顺序
CPU 一秒钟可以运行多达数 G 的微指令次数，通过核心的 CPU 调度可以让各进程被 CPU 所切换运行， 因此每个进程在一秒钟内或多或少都会被 CPU 执行部分的指令码。

##### Priority 与 Nice 值
**Linux 给予进程一个所谓的“优先执行序 （priority, PRI）”， 这个 PRI 值越低代表越优先的意思。不过这个 PRI 值是由核心动态调整的， 使用者无法直接调整 PRI 值的。
如果你想要调整程序的优先执行序时，就得要通过 Nice 值了**。
```
PRI（new） = PRI（old） + nice
```

- nice 值可调整的范围为`-20 ~ 19`；
- root 可随意调整自己或他人程序的 Nice 值，且范围为`-20 ~ 19`；
- 一般使用者仅可调整自己程序的 Nice 值，且范围仅为`0 ~ 19`（避免一般用户抢占系统资源）；
- 一般使用者仅可将 nice 值越调越高，例如本来 nice 为 5 ，则未来仅能调整到大于 5；

如何给予某个程序 nice 值呢？有两种方式，分别是：
- 一开始执行程序就立即给予一个特定的 nice 值：用**nice 指令**；
- 调整某个已经存在的 PID 的 nice 值：用**renice 指令**。

```bash
[root@study ~]# nice [-n 数字] command
选项与参数：
-n  ：后面接一个数值，数值的范围 -20 ~ 19。

# 用 root 给一个 nice 值为 -5 ，用于执行 vim ，并观察该程序
[root@study ~]# nice -n -5 vim &
```

通常系统的后台工作中，某些比较不重要的程序：例如备份工作，建议将nice值调大。

```bash
[root@study ~]# renice [number] PID
选项与参数：
PID ：某个程序的 ID

# 找出自己的 bash PID ，并将该 PID 的 nice 调整到 -5
[root@study ~]# renice -5 14836
14836 （process ID） old priority 10, new priority -5
```

### 查看系统资源
#### 观察内存使用情况 `free`
```bash
[root@study ~]# free [-b|-k|-m|-g|-h] [-t] [-s N -c N]
选项与参数：
-b  ：直接输入 free 时，显示的单位是 KBytes，我们可以使用 b（Bytes）, m（MBytes）
      k（KBytes）, 及 g（GBytes） 来显示单位喔！也可以直接让系统自己指定单位 （-h）
-t  ：在输出的最终结果，显示实体内存与 swap 的总量。
-s  ：可以让系统每几秒钟输出一次，不间断的一直输出的意思！对于系统观察挺有效！
-c  ：与 -s 同时处理～让 free 列出几次的意思
```

一般来说，**swap 最好不要被使用，尤其 swap 最好不要被使用超过 20% 以上， 如果发现 swap 的用量超过 20% ，那么，最好还是买实体内存来插吧。因为，Swap 的性能跟实体内存实在差很多，
而系统会使用到 swap， 绝对是因为实体内存不足了才会这样做的**。

#### 查阅系统与核心相关信息 `uname`
```bash
[root@study ~]# uname [-asrmpi]
选项与参数：
-a  ：所有系统相关的信息，包括下面的数据都会被列出来；
-s  ：系统核心名称
-r  ：核心的版本
-m  ：本系统的硬件名称，例如 i686 或 x86_64 等；
-p  ：CPU 的类型，与 -m 类似，只是显示的是 CPU 的类型！
-i  ：硬件的平台 （ix86）
```

#### 观察系统启动时间与工作负载 `uptime`
显示出目前系统已经开机多久的时间，以及 1, 5, 15 分钟的平均负载就是了。这个 uptime 可以显示出 top 画面的最上面一行。

#### netstat
这个指令比较常被用在网络的监控方面。
```bash
[root@study ~]# netstat -[atunlp]
选项与参数：
-a  ：将目前系统上所有的连线、监听、Socket 数据都列出来
-t  ：列出 tcp 网络封包的数据
-u  ：列出 udp 网络封包的数据
-n  ：不以程序的服务名称，以埠号 （port number） 来显示；
-l  ：列出目前正在网络监听 （listen） 的服务；
-p  ：列出该网络服务的程序 PID

# 列出目前系统已经创建的网络连线与 unix socket 状态
[root@study ~]# netstat
Active Internet connections （w/o servers） <==与网络较相关的部分
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 172.16.15.100:ssh       172.16.220.234:48300    ESTABLISHED
Active UNIX domain sockets （w/o servers）  <==与本机的程序自己的相关性（非网络）
Proto RefCnt Flags       Type       State         I-Node   Path
unix  2      [ ]         DGRAM                    1902     @/org/freedesktop/systemd1/notify
unix  2      [ ]         DGRAM                    1944     /run/systemd/shutdownd
....（中间省略）....
unix  3      [ ]         STREAM     CONNECTED     25425    @/tmp/.X11-unix/X0
unix  3      [ ]         STREAM     CONNECTED     28893
unix  3      [ ]         STREAM     CONNECTED     21262
```

先来看看网际网络连线情况的部分：
- Proto ：网络的封包协定，主要分为 TCP 与 UDP 封包；
- Recv-Q：非由使用者程序链接到此 socket 的复制的总 Bytes 数；
- Send-Q：非由远端主机传送过来的 acknowledged 总 Bytes 数；
- Local Address ：本地端的 IP:port 情况
- Foreign Address：远端主机的 IP:port 情况
- State ：连线状态，主要有创建（ESTABLISED）及监听（LISTEN）；

除了网络上的连线之外，其实 Linux 系统上面的程序是可以接收不同程序所发送来的信息，那就是 Linux 上头的socket file。
- Proto ：一般就是 unix；
- RefCnt：连接到此 socket 的程序数量；
- Flags ：连线的旗标；
- Type ：socket 存取的类型。主要有确认连线的 STREAM 与不需确认的 DGRAM 两种；
- State ：若为 CONNECTED 表示多个程序之间已经连线创建。
- Path ：连接到此 socket 的相关程序的路径！或者是相关数据输出的路径。

#### dmesg
分析核心产生的信息。不管是开机时候还是系统运行过程中，反正只要是核心产生的信息，都会被记录到内存中的某个保护区段。
dmesg 这个指令就能够将该区段的讯息读出来。可以加入这个管线指令`| more`来使画面暂停。

```bash
# 输出所有的核心开机时的信息
[root@study ~]# dmesg | more
```

#### vmstat
侦测系统资源变化。
```bash
[root@study ~]# vmstat [-a] [延迟 [总计侦测次数]] <==CPU/内存等信息
[root@study ~]# vmstat [-fs]                      <==内存相关
[root@study ~]# vmstat [-S 单位]                  <==设置显示数据的单位
[root@study ~]# vmstat [-d]                       <==与磁盘有关
[root@study ~]# vmstat [-p 分区]                <==与磁盘有关
选项与参数：
-a  ：使用 inactive/active（活跃与否） 取代 buffer/cache 的内存输出信息；
-f  ：开机到目前为止，系统复制 （fork） 的程序数；
-s  ：将一些事件 （开机至目前为止） 导致的内存变化情况列表说明；
-S  ：后面可以接单位，让显示的数据有单位。例如 K/M 取代 Bytes 的容量；
-d  ：列出磁盘的读写总量统计表
-p  ：后面列出分区，可显示该分区的读写总量统计表
```

## SELinux
SELinux 是 Security Enhanced Linux 的缩写，安全强化的 Linux 之意。

SELinux 当初设计的目标：避免资源的误用。

系统的帐号主要分为系统管理员 （root） 与一般用户，而这两种身份能否使用系统上面的文件资源则与 rwx 的权限设置有关。
这种存取文件系统的方式被称为**自主式存取控制 （Discretionary Access Control, DAC）**。基本上，就是依据程序的拥有者与文件资源的 rwx 权限来决定有无存取的能力。问题：

- root 具有最高的权限：如果不小心某支程序被有心人士取得， 且该程序属于 root 的权限，那么这支程序就可以在系统上进行任何资源的存取。
- 使用者可以取得程序来变更文件资源的存取权限：如果你不小心将某个目录的权限设置为 777 ，由于对任何人的权限会变成 rwx ，因此该目录就会被任何人所任意存取

为了避免 DAC 容易发生的问题，因此 SELinux 导入了**委任式存取控制 （Mandatory Access Control, MAC）** 的方法。

**他可以针对特定的程序与特定的文件资源来进行权限的控管！也就是说，即使你是 root，那么在使用不同的程序时，你所能取得的权限并不一定是 root ，而得要看当时该程序的设置而定。**

**针对控制的“主体”变成了“程序”而不是使用者**。

### SELinux 的运行模式
**SELinux 是通过 MAC 的方式来控管程序，他控制的主体是程序， 而目标则是该程序能否读取的“文件资源”**。

- 主体 （Subject）： SELinux 主要想要管理的就是程序（process）
- 目标 （Object）： 主体程序能否存取的“目标资源”一般就是文件系统
- 策略 （Policy）： 由于程序与文件数量庞大，因此 SELinux 会依据某些服务来制订基本的存取安全性策略。这些策略内还会有详细的规则（rule）来指定不同的服务开放某些资源的存取与否。
在目前的 CentOS 7.x 里面仅有提供三个主要的策略，分别是：
  - targeted：针对网络服务限制较多，针对本机限制较少，是默认的策略；
  - minimum：由 target 修订而来，仅针对选择的程序来保护！
  - mls：完整的 SELinux 限制，限制方面较为严格。建议使用默认的 targeted 策略即可。
- 安全性本文 （security context）： 主体能不能存取目标除了策略指定之外，主体与目标的安全性本文必须一致才能够顺利存取。这个安全性本文 （security context） 有点类似文件系统
的 rwx，安全性本文的内容与设置是非常重要的！如果设置错误，你的某些服务（主体程序）就无法存取文件系统（目标资源），当然就会一直出现“权限不符”的错误讯息了。

![](/images/linux-basic/selinux_1.gif)

#### 安全性本文 （Security Context）
安全性本文存在于主体程序中与目标文件资源中。程序在内存内，所以安全性本文可以存入是没问题。那文件的安全性本文是放置到文件的 inode 内的。

先来看看`/root`下面的文件的安全性本文：
```bash
[root@study ~]# ls -Z
-rw-------. root root system_u:object_r:admin_home_t:s0     anaconda-ks.cfg
-rw-r--r--. root root system_u:object_r:admin_home_t:s0     initial-setup-ks.cfg
-rw-r--r--. root root unconfined_u:object_r:admin_home_t:s0 regular_express.txt
```
安全性本文主要用冒号分为三个字段，这三个字段的意义为：
```bash
Identify:role:type
身份识别:角色:类型
```

- 身份识别（Identify），帐号方面的身份识别，几种常见的类型：
  - unconfined_u：不受限的用户，也就是说，该文件来自于不受限的程序所产生的。 例如，一般默认的 bash 环境是不受 SELinux 管制。
  - system_u：系统用户，大部分就是系统自己产生的文件
- 角色（Role），通过角色字段，我们可以知道这个数据是属于程序、文件资源还是代表使用者。一般的角色有：
  - object_r：代表的是文件或目录等文件资源，这应该是最常见的
  - system_r：代表的就是程序
- 类型（Type），在默认的 targeted 策略中，重要的在于这个类型（type）字段，一个主体程序能不能读取到这个文件资源，与类型字段有关。类型字段在文件与程序的定义不太相同，分别是：
  - type：在文件资源 （Object） 上面称为类型 （Type）
  - domain：在主体程序 （Subject） 则称为领域 （domain）

domain 需要与 type 搭配，则该程序才能够顺利的读取文件资源。


#### SELinux 三种模式的启动、关闭与观察
- enforcing：强制模式，代表 SELinux 运行中，且已经正确的开始限制 domain/type 了；
- permissive：宽容模式：代表 SELinux 运行中，不过仅会有警告讯息并不会实际限制 domain/type 的存取。这种模式可以运来作为 SELinux 的 debug 之用；
- disabled：关闭，SELinux 并没有实际运行。

![](/images/linux-basic/sselinux_3.jpg)

宽容（permissive）模式，这种模式也是不会将主体程序抵挡（所以箭头是可以直接穿透的），不过万一没有通过策略规则，或者是安全本文的比对时，那么该读写动作将会被纪录起来（log），
可作为未来检查问题的判断依据。

#### SELinux 的启动与关闭
**如果改变了策略则需要重新开机；如果由 enforcing 或 permissive 改成 disabled ，或由 disabled 改成其他两个，那也必须要重新开机。这是因为 SELinux 是整合到核心里面去的，
只可以在 SELinux 运行下切换成为强制（enforcing）或宽容（permissive）模式，不能够直接关闭 SELinux 的**。

如果从 disable 转到启动 SELinux 的模式时，**由于系统必须要针对文件写入安全性本文的信息，因此开机过程会花费不少时间在等待重新写入 SELinux 安全性本文**。
开机成功后，再使用`getenforce`或`sestatus`来观察看看有否成功的启动到 Enforcing 的模式：
```bash
[root@study ~]# setenforce [0|1]
选项与参数：
0 ：转成 permissive 宽容模式；
1 ：转成 Enforcing 强制模式

# 将 SELinux 在 Enforcing 与 permissive 之间切换与观察
[root@study ~]# setenforce 0
[root@study ~]# getenforce
Permissive
```
setenforce 无法在 Disabled 的模式下面进行模式的切换。

## 系统服务（daemons）
从 CentOS 7.x 以后， 改用 systemd 这个启动服务管理机制，systemd 有什么好处？
- 平行处理所有服务，加速开机流程： 旧的 init 启动脚本是“一项一项任务依序启动”的模式，因此不相依的服务也是得要一个一个的等待。
-  systemd 全部就是仅有一只 systemd 服务搭配 systemctl 指令来处理，无须其他额外的指令来支持。不像 systemV 还要 init, chkconfig, service... 等等指令。
此外， systemd 由于常驻内存，因此任何要求 （on-demand） 都可以立即处理后续的 daemon 启动的任务。
- systemd 可以自订服务相依性的检查。
- 依 daemon 功能分类， systemd 先定义所有的服务为一个服务单位 （unit），并将该 unit 归类到不同的服务类型 （type） 去。systemd 将服务单位 （unit） 区分为 service, socket, target,
path, snapshot, timer 等多种不同的类型（type），方便分类与记忆。
- 将多个 daemons 集合成为一个群组
-  systemd 是可以相容于 init 的启动脚本的，因此，旧的 init 启动脚本也能够通过 systemd 来管理

### systemd 的配置文件放置目录
- `/usr/lib/systemd/system/`：每个服务最主要的启动脚本设置，有点类似的`/etc/init.d`下面的文件；
- `/run/systemd/system/`：系统执行过程中所产生的服务脚本，这些脚本的优先序要比`/usr/lib/systemd/system/`高
- `/etc/systemd/system/`：管理员依据主机系统的需求所创建的执行脚本，其实这个目录有点像`/etc/rc.d/rc5.d/Sxx `类的功能，执行优先序又比`/run/systemd/system/`高

也就是说，到底系统开机会不会执行某些服务其实是看`/etc/systemd/system/`下面的设置。该目录下面就是一大堆链接文件。而实际执行的 systemd 启动脚本配置文件，
其实都是放置在`/usr/lib/systemd/system/`下面的。因此如果你想要修改某个服务启动的设置，应该要去`/usr/lib/systemd/system/`下面修改。

### systemd 的 unit 类型分类说明

|  扩展名     | 主要服务功能   |
| --------   | -----  |
| `.service`  | 一般服务类型 （service unit）：主要是系统服务，包括服务器本身所需要的本机服务以及网络服务都是，这也是最常见的类型 |
| `.socket`  | 内部程序数据交换的 socket unit ：主要是 IPC （Inter-process communication） 的传输讯息 socket file 功能。  |
| `.target`  | 执行环境类型 （target unit）：其实是一群 unit 的集合 |
| `.mount`，`.automount`  | 文件系统挂载相关的服务 （automount unit / mount unit）：例如来自网络的自动挂载、NFS 文件系统挂载等与文件系统相关性较高的程序管理。 |
| `.path`  | 侦测特定文件或目录类型 （path unit）：某些服务需要侦测某些特定的目录来提供伫列服务，例如最常见的打印服务，就是通过侦测打印伫列目录来启动打印功能 |
| `.timer`  | 循环执行的服务 （timer unit）：这个东西有点类似 anacrontab 喔！不过是由 systemd 主动提供的，比 anacrontab 更加有弹性 |

## systemctl 管理服务
```bash
[root@study ~]# systemctl [command] [unit]
command 主要有：
start     ：立刻启动后面接的 unit
stop      ：立刻关闭后面接的 unit
restart   ：立刻关闭后启动后面接的 unit，亦即执行 stop 再 start 的意思
reload    ：不关闭后面接的 unit 的情况下，重新载入配置文件，让设置生效
enable    ：设置下次开机时，后面接的 unit 会被启动
disable   ：设置下次开机时，后面接的 unit 不会被启动
status    ：目前后面接的这个 unit 的状态，会列出有没有正在执行、开机默认执行否、登录等信息等！
is-active ：目前有没有正在运行中
is-enable ：开机时有没有默认要启用这个 unit
```

### 通过 systemctl 观察系统上所有的服务
```bash
[root@study ~]# systemctl [command] [--type=TYPE] [--all]
command:
    list-units      ：依据 unit 列出目前有启动的 unit。若加上 --all 才会列出没启动的。
    list-unit-files ：依据 /usr/lib/systemd/system/ 内的文件，将所有文件列表说明。
--type=TYPE：就是之前提到的 unit type，主要有 service, socket, target 等
```

### 通过 systemctl 分析各服务之间的相依性
```bash
[root@study ~]# systemctl list-dependencies [unit] [--reverse]
选项与参数：
--reverse ：反向追踪谁使用这个 unit 的意思

[root@study ~]# systemctl list-dependencies
default.target
├─abrt-ccpp.service
├─abrt-oops.service
├─vsftpd.service
├─basic.target
│ ├─alsa-restore.service
│ ├─alsa-state.service
```
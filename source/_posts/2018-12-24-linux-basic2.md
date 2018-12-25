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

#### 实时运行区


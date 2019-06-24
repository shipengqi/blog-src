---
title: Nodejs文件监听
date: 2018-03-20 15:18:14
categories: ["Node.js"]
---

Nodejs，实现文件监听，可以使用[fs.watch](https://nodejs.org/api/fs.html#fs_fs_watch_filename_options_listener)和[fs.watchFile](https://nodejs.org/api/fs.html#fs_fs_watchfile_filename_options_listener)。


也可以通过第三方库来实现，本文主要介绍[chokidar](https://www.npmjs.com/package/chokidar)的使用。

<!-- more -->

## fs.watch

官网例子：
``` javascript
fs.watch('somedir', (eventType, filename) => {
  console.log(`event type is: ${eventType}`);
  if (filename) {
    console.log(`filename provided: ${filename}`);
  } else {
    console.log('filename not provided');
  }
});
```

`fs.watch`的不支持子文件夹的侦听，而且在很多情况下会侦听到两次事件。

## chokidar

安装什么的就不介绍了，参考[官方文档](https://www.npmjs.com/package/chokidar)。

例子：
``` javascript

class ContentPackWatcher {
  constructor(robot, options = {awaitWriteFinish: true}) {
    let dirPath = `${process.env.HUBOT_ENTERPRISE_PACKAGES_DIR}/*.zip`;
    this.watcher = Chokidar.watch(dirPath, options);
    this.watcher
      .on('add', this.addFileListener.bind(this))
      .on('addDir', this.addDirectoryListener.bind(this))
      .on('change', this.fileChangeListener.bind(this))
      .on('unlink', this.fileDeleteListener.bind(this))
      .on('unlinkDir', this.directoryDeleteListener.bind(this))
      .on('error', this.errorListener.bind(this))
      .on('ready', this.readyListener.bind(this));
  }

  getWatched() {
    return this.watcher.getWatched();
  }

  stopWatch(paths) {
    this.watcher.unwatch(paths);
  }

  readyListener() {
    logger.info('Initial scan complete. Ready for changes.');
  }

  errorListener(error) {
    logger.error('Error happened', error)
  }

  //add new file
  addFileListener(filePath, stats) {
    if (stats.size > 0) {
      logger.info(`File ${filePath} has been added, size: ${stats.size}.`);
    }
  }

  //add new directory
  addDirectoryListener(dirPath) {
    logger.info(`Directory ${dirPath} has been added.`);
  }

  //watch file change
  fileChangeListener(filePath, stats) {
    if (stats.size > 0) {
      logger.info(`File ${filePath} has been changed, size: ${stats.size}.`);
    }
  }

  //watch file delete
  fileDeleteListener(filePath) {
    logger.info(`File ${filePath} has been removed.`);
  }

  //watch directory delete
  directoryDeleteListener(dirPath) {
    logger.info(`Directory ${dirPath} has been removed.`);
  }

}

```
## API
```javascript
chokidar.watch(paths, [options])
```

- paths: 可以是一个字符串数组或一个字符串。
- options: 对象。
  - persistent: 默认`true`，进程是否持续监听文件，如果设置为`false`，当使用`fsevents`监听时，`ready`之后不会触发任何监听事件。
  - ignored: 忽略某些文件的监听，
  - ignoreInitial: 默认`false`，如果设置为false,在初始化`chokidar`实例时，如果监听到匹配的文件也会被触发`add/addDir`事件。
  - followSymlinks: 默认`true`，如果设置为false,只看符号链接本身的变化。
  - cwd: 监听的路径的 base 目录。
  - disableGlobbing: 默认`false`，如果设置为 true,那么传递给`.watch()`和`add()`的字符串被视为文字路径名,即使它们看起来就像 globs。
  - usePolling: 默认`false`，是否使用fs.watchFile (backed by polling), 或者 fs.watch，如果轮询导致CPU占用过高，可以设置为`false`。
  它通常需要设置`true`当通过网络监听文件时和非标准的情况下。在OS X 上设置为`true`，会覆盖`useFsEvents`，也可以设置`CHOKIDAR_USEPOLLING`环境变量
  来覆盖它。
  - Polling-specific设置（只在usePolling: true是有效）
    - interval:(default: 100).文件系统轮询时间间隔，也可以通过设置环境变量`CHOKIDAR_INTERVAL`来覆盖它。
    - binaryInterval:(default: 300).二进制文件系统轮询时间间隔。
  - useFsEvents:(default: true on OS X)当`fsevents` 的监听接口可用时，是否启用。当显式地设置为`true`,`fsevents` 取代`usePolling`。
  在OS X 上设置为`false`时，`usePolling: true`变为默认。
  - alwaysStat: 默认`false`，如果`add`,`addDir`，`change`事件依赖`fs.Stats`对象（callback的第二个参数），设置为`true`时，可以确保传入这个对象，尽管
  它不是可用的。
  - depth: 默认`undefined`，遍历子目录的层级。
  - awaitWriteFinish: 默认`false`，默认情况下，文件第一次出现在磁盘上，文件被写完之前，就会触发`add`事件。此外,在某些情况下会触发`change`事件，
  在一些情况下，特别是监听大文件，需要在等待写操作完成以后回复一个文件创建或者修改。设置为`true`，会检查文件大小，直到文件在设置的时间内(stabilityThreshold)不再改变，才会
  触发`add`或者`change`事件。设置适当的时间依赖系统和硬件。`awaitWriteFinish`可以是一个`object`，包含下面的属性:
    - stabilityThreshold: (default: 2000)单位毫秒，等待文件大小不再改变的时间，在设置时间之后触发事件。
    - pollInterval: (default: 100)，检查文件大小的时间间隔。
  - ignorePermissionErrors: 默认`false`，忽略没有权限操作文件的error。

## 事件

`chokidar`可以通过`on`方法监听到下面的事件：

- add, 文件添加
- addDir, 文件夹添加
- change, 文件变化
- unlink, 文件删除
- unlinkDir, 文件夹删除
- ready
- raw
- error

除了`ready`，`raw`，`error`这三个事件，其他事件触发都可以拿到文件路径。

## 方法

- .add(path / paths): 添加监听文件。参数可以是一个字符串数组或一个字符串。
- .on(event, callback): 监听事件，除了`ready`，`raw`，`error`这三个事件，其他事件的`callback`函数的第一个参数是文件路径。
- .unwatch(path / paths): 停止监听某个文件。参数可以是一个字符串数组或一个字符串。
- .close(): 删除所有文件监听。
- .getWatched(): 返回一个包含所有被监听的文件的对象。
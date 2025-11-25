---
title: epoll详解
date: 2025-11-25 17:05:46
tags: [epoll,原理]
---
####    epoll 是 Linux 下高效的 I/O 多路复用机制，支持监控大量文件描述符（FD）的读写状态。其原理基于事件驱动：通过 epoll_ctl 注册 FD 及感兴趣事件，内核维护就绪队列；调用 epoll_wait 时，仅返回就绪的 FD，避免遍历所有 FD。相比 select/poll，epoll 无重复拷贝、支持边缘触发（ET）和水平触发（LT），适用于高并发网络服务（如 Nginx）

![epoll详解](https://cdn.jsdelivr.net/gh/loveTheresia/loveTheresia.github.io-source@2025.11/source/image/epoll详解.png)

### 点击获取思维导图：[Docker教程](https://cdn.jsdelivr.net/gh/loveTheresia/loveTheresia.github.io-source/xmind/epoll详解.xmind)
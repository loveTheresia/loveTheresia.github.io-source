---
title: C++异步编程
date: 2025-11-23 23:13:01
tags: [C++,代码]
top: 1
---
####    还在手动new和delete？C++ <memory>头文件用智能指针彻底改变了内存管理。看这行代码：std::shared_ptr<int> p = std::make_shared<int>(42);。它不仅创建对象，更引入了引用计数机制，当最后一个指针销毁时，内存自动释放。本文将深入其技术细节，助你告别内存泄漏
![memory头文件](https://cdn.jsdelivr.net/gh/loveTheresia/loveTheresia.github.io@2025/source/_posts/memory头文件/memory库.png)

文件地址：
https://github.com/loveTheresia/loveTheresia.github.io/blob/f66f4c054ae2fcd2eb6788f50135526806e32d56/xmind/memory%E5%A4%B4%E6%96%87%E4%BB%B6.xmind
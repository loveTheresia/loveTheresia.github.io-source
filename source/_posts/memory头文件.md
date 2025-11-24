---
title: memory头文件
date: 2025-11-23 23:13:01
tags: [C++,代码]
top: 1
---
####    还在手动new和delete？C++ <memory>头文件用智能指针彻底改变了内存管理。看这行代码：std::shared_ptr<int> p = std::make_shared<int>(42);。它不仅创建对象，更引入了引用计数机制，当最后一个指针销毁时，内存自动释放。本文将深入其技术细节，助你告别内存泄漏
![memory头文件](https://cdn.jsdelivr.net/gh/loveTheresia/loveTheresia.github.io-source@2025.11/source/image/memory库.png)
### 点击获取思维导图：[memory头文件](https://cdn.jsdelivr.net/gh/loveTheresia/loveTheresia.github.io-source/xmind/memory头文件.xmind)

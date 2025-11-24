---
title: C++异步编程
date: 2025-11-23 23:13:01
tags: [C++,代码]
top: 1
---
####    C++中，函数指针、lambda与仿函数等可调用物类型各异，如何统一管理？<functional>头文件给出了答案。其技术核心是std::function——一个强大的类型擦除包装器，它能将任意可调用对象封装为统一实体，实现泛型编程的极致灵活性。
![Function头文件](https://cdn.jsdelivr.net/gh/loveTheresia/loveTheresia.github.io@2025/source/_posts/Function头文件/%23includefunction.png)

文件地址：
https://github.com/loveTheresia/loveTheresia.github.io/blob/f66f4c054ae2fcd2eb6788f50135526806e32d56/xmind/Docker%20(1).xmind
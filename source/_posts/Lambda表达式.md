---
title: C++异步编程
date: 2025-11-23 23:13:01
tags: [C++,代码]
top: 1
---
####    只需一行代码：std::sort(v.begin(), v.end(), [](int a, int b){ return a < b; }); 即可替代冗长的函数对象。本文将深入剖析其语法，从捕获列表[=]、[&]到返回值推导，助你掌握这种强大的就地编程技巧
![Lambda表达式](https://cdn.jsdelivr.net/gh/loveTheresia/loveTheresia.github.io@2025/source/_posts/Lambda%E8%A1%A8%E8%BE%BE%E5%BC%8F/Lambda%E8%A1%A8%E8%BE%BE%E5%BC%8F.png)

文件地址：
https://github.com/loveTheresia/loveTheresia.github.io/blob/f66f4c054ae2fcd2eb6788f50135526806e32d56/xmind/Lambda%E8%A1%A8%E8%BE%BE%E5%BC%8F.xmind
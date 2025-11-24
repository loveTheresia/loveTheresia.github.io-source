---
title: CMake使用
date: 2025-11-23 23:13:01
tags: [CMake,工具]
top: 100
---
官网：www.cmake.org
优点：
1、开源代码，使用类BSD许可发布。
2、跨平台，并可以生成native编译配置文件，在linux/Unix平台，生成makefile,在苹果平台可以生成Xcode,在windows平台，可以生成MSVC的工程文件。
3、能够管理大型项目。
4、简化编译构建过程和编译过程。cmake的工具链：cmake+make。
5、高效率，因为cmake在工具链中没有libtool。
6、可扩展，可以为cmake编写特定功能的模块，扩展cmake功能。

缺点：
1、cmake只是看起来比较简单，使用并不简单；
2、每个项目使用一个CMakeLists.txt（每个目录一个），使用的是cmake语法。
3、cmake跟已有体系配合不是特别的理想，比如pkgconfig。

![CMake](https://cdn.jsdelivr.net/gh/loveTheresia/loveTheresia.github.io-source@2025.11/source/image/%E5%AE%8F.png)
文件地址：
https://github.com/loveTheresia/loveTheresia.github.io/blob/f66f4c054ae2fcd2eb6788f50135526806e32d56/xmind/CMake.xmind

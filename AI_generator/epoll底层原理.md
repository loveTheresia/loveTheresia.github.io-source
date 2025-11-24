epoll 是 Linux 下高效实现 I/O 多路复用的机制，其底层主要依赖以下核心数据结构及协作机制：
---
## 一、核心数据结构
### 1. eventpoll
每个 epoll 实例对应一个 `eventpoll` 结构体，包含以下关键成员：
- `struct rb_root rbr`：红黑树的根节点，用于高效管理所有被监控的文件描述符（socket）。
- `struct list_head rdllist`：双向链表，存储所有已经就绪（即发生事件）的文件描述符对应的 `epitem`。
- `wait_queue_head_t wq`：等待队列，用于管理调用 `epoll_wait` 阻塞的进程。
- `spinlock_t lock`、`struct mutex mtx`：自旋锁和互斥锁，保护并发访问。
### 2. epitem
每个被监控的文件描述符对应一个 `epitem` 结构体，关键成员包括：
- `struct rb_node rbn`：红黑树节点，使 `epitem` 能够插入 `eventpoll` 的红黑树中。
- `struct list_head rdllink`：双向链表节点，用于在事件就绪时将 `epitem` 挂到 `eventpoll` 的 `rdllist` 上。
- `struct epoll_filefd ffd`：包含文件描述符信息。
- `struct eventpoll *ep`：指向所属的 `eventpoll` 实例。
- `struct epoll_event event`：用户关注的事件类型（如 EPOLLIN、EPOLLOUT）。
### 3. 红黑树
- 用于管理所有被监控的文件描述符，支持高效的增、删、查操作，时间复杂度为 O(logN)。
- 避免了每次调用 `epoll_wait` 时都要传递整个 fd 集合的问题。
### 4. 双向链表（rdllist）
- 用于存放所有已经就绪的 `epitem`。
- `epoll_wait` 只需检查该链表，无需遍历所有 fd，大幅提高效率。
---
## 二、协作机制与工作流程
### 1. epoll_create()
- 创建一个 `eventpoll` 实例，初始化红黑树和双向链表。
- 返回一个 epoll 文件描述符（epfd），用于后续操作。
### 2. epoll_ctl()
- 用于向红黑树中添加、修改或删除文件描述符（`epitem`）。
- 每次添加 fd 时，内核都会为该 fd 注册一个回调函数 `ep_poll_callback`。
- 当该 fd 上有事件发生时（如数据到达），内核会调用回调函数将对应的 `epitem` 插入 `rdllist`。
### 3. epoll_wait()
- 阻塞等待 `rdllist` 非空。
- 当有事件就绪，将 `rdllist` 中的 `epitem` 拷贝到用户态，并返回就绪的 fd 数量。
- 如果 `rdllist` 为空，进程阻塞，直到有事件发生或超时。
### 4. 回调机制
- 每个被监控的 fd 都与设备驱动（如网卡）建立了回调关系。
- 当事件发生时，驱动调用 `ep_poll_callback`，将对应的 `epitem` 插入 `rdllist`，并唤醒等待队列中的进程。
---
## 三、高效多路复用的关键点
1. **事件驱动 + 回调**：epoll 不像 select/poll 每次都要轮询所有 fd，而是通过回调机制仅处理就绪的 fd，极大减少系统调用和遍历开销。
2. **红黑树 + 双向链表**：
   - 红黑树高效管理所有 fd，支持动态增删。
   - 双向链表仅存储就绪 fd，`epoll_wait` 只需处理链表，时间复杂度 O(1)。
3. **避免重复拷贝**：`epoll_ctl` 只需注册一次 fd，后续 `epoll_wait` 不再传递整个 fd 集合，减少用户态与内核态的数据拷贝。
4. **支持大规模并发**：没有 fd 数量限制（理论上受系统资源限制），适合百万级并发连接。
---
## 四、补充：LT 与 ET 模式
- **LT（Level Triggered，水平触发）**：只要 fd 未处理完，每次 `epoll_wait` 都会返回。
- **ET（Edge Triggered，边缘触发）**：仅当状态发生变化时触发一次，必须一次性读完/写完数据，否则不会再次通知，效率更高。
---
## 五、小结
epoll 的多路复用机制通过红黑树高效管理所有 fd，双向链表收集就绪事件，结合回调机制和事件驱动，实现高并发场景下的高效 I/O 管理。其设计思路解决了 select/poll 在 fd 数量多、重复轮询和拷贝开销大的痛点，是 Linux 下高性能网络编程的核心工具。
---
## 参考来源
- 【1】看云：epoll原理详解及epoll反应堆模型
- 【2】【4】【7】【9】【12】【15】知乎、CSDN、博客园等专栏对 epoll 底层结构、源码及工作流程的详细分析
- 【20】epoll内核实现机制总结
如需进一步了解，可参考上述源码剖析与结构图解。


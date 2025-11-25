---
title: promise_type 和 TaskAwaiter 的关系
date: 2025-11-25 16:58:44
tags: [协程]
top: 1
---
# promise_type 和 TaskAwaiter 的关系

这是一个非常棒的问题，它触及了 C++20 协程实现中最核心、最精妙的关系。
简单来说，`promise_type` 和 `TaskAwaiter` 是**协程内部控制器**和**协程间通信桥梁**的关系。它们不是父子或组合关系，而是一种为了完成“等待一个协程”这个任务而紧密协作的**双向契约**。
让我们用一个比喻来理解：
*   **`promise_type`**：是一个**被调用协程**的**内部经理**。它全权负责这个协程的内部事务：如何开始、如何处理返回值、如何处理异常、以及结束后该做什么。
*   **`TaskAwaiter`**：是一个**外部协调员**。当一个**调用者协程**想要等待这个被调用协程时，这个协调员就被创建出来，负责在两者之间传递消息和结果。
---
### 它们如何协作：一次完整的 `co_await` 生命周期
假设我们有以下代码：
```cpp
Task<int> inner_task() {
    co_return 42;
}
Task<void> outer_task() {
    int result = co_await inner_task(); // <-- 关键点在这里
    // ...
}
```
当 `outer_task` 执行到 `co_await inner_task()` 时，`promise_type` 和 `TaskAwaiter` 开始了它们的精妙协作：
#### 第 1 步：创建“协调员” (`TaskAwaiter`)
1.  `co_await` 表达式首先在 `inner_task()` 返回的 `Task<int>` 对象上调用 `operator co_await()`。
2.  这个操作会创建一个 `TaskAwaiter<int>` 对象。我们称之为 `awaiter`。
3.  在 `awaiter` 的构造函数中，发生了最关键的**第一次握手**：
    ```cpp
    // TaskAwaiter 的构造函数
    template <class P>
    explicit TaskAwaiter(std::coroutine_handle<P> coroutine)
        : mCalleeCoroutine(coroutine) { 
        // 【关键联系】
        // awaiter 告诉被调用协程的 promise：“我就是你的协调员”
        coroutine.promise().mAwaiter = this; 
    }
    ```
    *   `awaiter` 获取了 `inner_task` 的协程句柄。
    *   通过这个句柄，它找到了 `inner_task` 的 `promise_type` 对象。
    *   它将自己的地址 (`this`) 存入了 `promise_type` 的一个成员变量 `mAwaiter` 中。
    现在，`inner_task` 的“内部经理” (`promise_type`) 知道了谁是它的“外部协调员” (`TaskAwaiter`)。
#### 第 2 步：挂起调用者 (`await_suspend`)
1.  协程框架检查 `awaiter.await_ready()`，发现 `inner_task` 还没完成，返回 `false`。
2.  框架调用 `awaiter.await_suspend(outer_task_handle)`。
3.  `awaiter` 保存 `outer_task` 的句柄到 `mCallerCoroutine`，然后返回 `inner_task` 的句柄 (`mCalleeCoroutine`)，让 `inner_task` 立即开始执行。
4.  `outer_task` 被挂起，等待被唤醒。
#### 第 3 步：被调用协程执行并返回结果
1.  `inner_task` 开始执行，最终到达 `co_return 42;`。
2.  这个语句会触发 `inner_task` 的 `promise_type::return_value(42)` 方法。
3.  在 `promise_type::return_value` 内部，发生了**第二次握手**：
    ```cpp
    // promise_type 的一个可能实现
    template<class T>
    struct TaskPromise {
        TaskAwaiter<T>* mAwaiter = nullptr; // 在第1步被设置
        void return_value(T value) {
            // 【关键联系】
            // “内部经理”将结果交给“外部协调员”
            if (mAwaiter) {
                mAwaiter->returnValue(std::move(value));
            }
        }
        // ...
    };
    ```
    *   `promise_type` 查看自己保存的 `mAwaiter` 指针。
    *   它调用 `mAwaiter->returnValue(42)`，把返回值 `42` 存储到了 `TaskAwaiter` 对象的 `mResult` 成员中。
#### 第 4 步：恢复调用者 (`await_resume`)
1.  在 `returnValue` 之后，`promise_type` 的工作基本完成。它会恢复之前保存的调用者协程（`outer_task`）。
2.  `outer_task` 从挂起点恢复，协程框架调用 `awaiter.await_resume()`。
3.  `await_resume()` 从 `mResult` 中取出 `42`，并将其作为 `co_await` 表达式的结果返回。
4.  `int result = 42;` 这行代码完成，`outer_task` 继续向下执行。
---
### 关系总结
| 特性 | `promise_type` (内部经理) | `TaskAwaiter` (外部协调员) |
| :--- | :--- | :--- |
| **职责** | 管理单个协程的生命周期、返回值和异常。 | 管理两个协程（调用者和被调用者）之间的等待和结果传递。 |
| **生命周期** | 与它所属的协程绑定，协程开始时创建，结束时销毁。 | 在 `co_await` 表达式求值时创建，表达式结束时销毁。 |
| **关键联系** | 持有一个指向 `TaskAwaiter` 的指针 (`mAwaiter`)，以便在 `co_return` 时通知它。 | 在构造时，将自己的地址注册到 `promise_type` 中。 |
| **数据流向** | `promise_type` -> `TaskAwaiter` (传递结果/异常) | `TaskAwaiter` -> 调用者协程 (通过 `await_resume` 返回结果) |
| **协作模式** | **双向引用**。`Awaiter` 引用 `Promise` 来获取句柄，`Promise` 引用 `Awaiter` 来回传结果。 |
**核心思想**：这种设计将协程的**内部状态管理** (`promise_type`) 和**外部交互逻辑** (`TaskAwaiter`) 彻底解耦。`promise_type` 只关心自己，它不需要知道是谁在等待它，它只需要把结果交给一个“协调员”即可。而 `TaskAwaiter` 则专门负责处理等待的细节，包括保存调用者、传递结果、处理异常等。
这种清晰的职责分离和双向契约，是 C++20 协程能够实现强大组合能力的基础。


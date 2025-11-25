---
title: 详解Redis Pub-Sub服务
date: 2025-11-25 16:32:35
tags:
top: 1
---
在聊天应用中，这是实现**实时消息广播**的核心机制。
我们将从三个层面来深入探讨：
1.  **通用原理**：什么是 Pub/Sub？
2.  **Redis 实现**：Redis 是如何实现 Pub/Sub 的？
3.  **在聊天应用中的具体应用**：代码是如何工作的？
---
### 1. 通用原理：解耦的艺术
发布/订阅模式是一种消息通信范式，它的目标是**解耦消息的发送者（发布者）和接收者（订阅者）**。
想象一下报纸投递系统：
*   **发布者**：报社。它只管印报纸，然后扔到特定的邮筒（频道）里。
*   **订阅者**：你。你告诉邮递员你对哪些邮筒（频道）感兴趣。
*   **频道**：邮筒，比如“体育新闻邮筒”、“财经新闻邮筒”。
*   **消息**：报纸。
**核心特点：**
*   **解耦**：报社（发布者）完全不知道是谁（订阅者）在订阅，甚至不知道有多少人订阅。它只管向邮筒（频道）里投递（发布）报纸（消息）。
*   **异步**：发布者发布消息后，不需要等待订阅者接收。消息的传递是异步的。
*   **一对多**：一个消息可以被多个订阅者同时接收。
这种模式在软件架构中带来了巨大的好处，特别是**系统扩展性和灵活性**的提升。
---
### 2. Redis 实现：轻量级的实时消息总线
Redis 内置了强大的 Pub/Sub 功能，使其成为实现这一模式的理想选择。
#### **核心命令**
*   `SUBSCRIBE channel [channel ...]`：客户端订阅一个或多个频道。
*   `PUBLISH channel message`：客户端向指定频道发布一条消息。
*   `UNSUBSCRIBE [channel ...]`：取消订阅。
#### **工作机制**
1.  **订阅**：当一个客户端执行 `SUBSCRIBE chat-room-1` 时，Redis 服务器会在内部维护一个字典，记录 `chat-room-1` 这个频道有哪些订阅者（即哪些客户端连接）。
2.  **发布**：当另一个客户端执行 `PUBLISH chat-room-1 "hello everyone"` 时，Redis 服务器会查找 `chat-room-1` 频道的订阅者列表，然后将消息 `"hello everyone"` **立即推送给所有订阅者**。
3.  **接收**：订阅的客户端会异步收到消息，然后可以执行相应的回调逻辑。
#### **关键特性与限制**
*   **即发即弃**：这是 Redis Pub/Sub 最重要的特性。消息被发布后，Redis 会立即推送给所有在线的订阅者，然后**消息就消失了**。它不会存储在服务器上。
    *   **优点**：极低的延迟，非常适合实时聊天、实时通知等场景。
    *   **缺点**：如果一个订阅者当时离线，它就永远错过了这条消息。没有持久化，没有消息堆积。
*   **模式订阅**：支持通配符订阅，如 `PSUBSCRIBE news-*` 可以订阅所有以 `news-` 开头的频道。
---
### 3. 在聊天应用中的具体应用
现在，我们将这些原理与你的 `chat_websocket.cpp` 代码对应起来。
#### **角色映射**
| Pub/SUB 角色 | 聊天应用中的对应物 |
| :--- | :--- |
| **发布者** | `event_handler_visitor::operator()(client_messages_event&)` |
| **订阅者** | 每个 `chat_websocket_session` 对象（代表一个 WebSocket 连接） |
| **频道** | 聊天室 ID（如 `"beast"`, `"async"`） |
| **消息** | 序列化后的 `server_messages_event` JSON 字符串 |
| **消息中心** | Redis 服务器 + `pubsub_service` |
#### **核心流程解析**
##### **订阅：成为消息接收者**
当一个新用户通过 WebSocket 连接到服务器时：
```cpp
// chat_websocket_session::run()
auto pubsub_guard = st_->pubsub().subscribe_guarded(shared_from_this(), room_ids);
```
*   **发生了什么**：
    1.  `st_->pubsub()` 获取到全局的 Pub/Sub 服务实例。
    2.  `subscribe_guarded()` 被调用。它内部会执行 Redis 的 `SUBSCRIBE` 命令，订阅所有预定义的聊天室（`room_ids`）。
    3.  `shared_from_this()`：将当前 `chat_websocket_session` 对象（实现了 `message_subscriber` 接口）作为一个订阅者注册进去。
    4.  **RAII 守卫**：返回的 `pubsub_guard` 是一个 RAII 对象。它的生命周期与 `chat_websocket_session` 绑定。当连接断开，`chat_websocket_session` 对象被销毁时，`pubsub_guard` 的析构函数会自动执行 `UNSUBSCRIBE`，防止出现“僵尸订阅”。
##### **接收广播：`on_message` 回调**
```cpp
// chat_websocket_session::on_message()
void on_message(std::string_view serialized_message, boost::asio::yield_context yield) override final
{
    ws_.write(serialized_message, yield);
}
```
*   **发生了什么**：
    1.  当任何用户向 `chat_websocket_session` 已订阅的频道（如 `"beast"`）发布消息时，Redis 会推送这条消息。
    2.  `pubsub_service` 接收到消息后，会查找所有订阅了 `"beast"` 频道的会话。
    3.  它会调用每个会话的 `on_message` 回调函数，并将消息内容 `serialized_message` 作为参数传入。
    4.  `on_message` 函数非常简单：直接将收到的消息通过 WebSocket 写回给客户端。
##### **发布：成为消息发送者**
当一个用户在客户端发送聊天消息时：
```cpp
// event_handler_visitor::operator()(client_messages_event&)
// ... 构造 server_evt ...
st_.pubsub().publish(evt.roomId, server_evt.to_json());
```
*   **发生了什么**：
    1.  `event_handler_visitor` 解析客户端消息，构造了一个包含完整信息（ID、内容、时间戳、发送者）的 `server_messages_event`。
    2.  `server_evt.to_json()` 将其序列化为 JSON 字符串。
    3.  `st_.pubsub().publish()` 被调用。它内部执行 Redis 的 `PUBLISH` 命令，将 JSON 消息发送到指定的聊天室频道（`evt.roomId`）。
    4.  Redis 立即将这条消息广播给所有订阅了该频道的客户端，包括消息发送者自己。
---
### 总结与设计优势
这个 Pub/Sub 服务的设计是整个聊天应用的**神经中枢**，它带来了以下关键优势：
1.  **极致的解耦**：处理消息的业务逻辑（`event_handler_visitor`）完全不需要知道 WebSocket 连接管理的细节。它只管向一个“逻辑频道”发消息，分发工作由 Pub/Sub 服务和 Redis 完成。
2.  **无缝的水平扩展**：这是最强大的优势。如果你的聊天用户量激增，你可以启动多个聊天服务器实例。只要这些实例都连接到同一个 Redis，它们的 Pub/Sub 服务就会协同工作。一个实例上收到的消息，会通过 Redis 广播给所有实例上的所有订阅者。这是构建分布式实时系统的基石。
3.  **高性能**：Redis 的 Pub/Sub 是内存操作，延迟极低，非常适合实时通信的场景。
4.  **健壮的生命周期管理**：通过 `subscribe_guarded` 返回的 RAII 守卫，完美解决了订阅的自动清理问题，避免了资源泄漏，代码既安全又简洁。
总而言之，`pubsub_service` 不仅仅是一个功能，它是一种架构思想的具体实现，它将复杂的分布式通信问题，优雅地简化为了发布和订阅两个简单的操作。

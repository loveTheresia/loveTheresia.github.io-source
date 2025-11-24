## C++ WebServer 中的 SharedState 通用实现
---
### 1. **SharedState 的概念与作用**
`SharedState` 是一种设计模式，用于在多线程/多会话环境中共享同一状态对象。它通常以单例（Singleton）或 Borg 模式实现，确保：
- 所有会话/线程访问的是同一个状态对象，而非各自独立。
- 状态的变更对所有会话立即可见。
- 资源（如数据库连接池、全局配置、缓存）高效复用，避免重复创建。
在 C++ WebServer 中，SharedState 通常用于：
- 全局配置管理
- 数据库连接池
- 线程池
- 缓存系统
- 用户会话的集中管理（如分布式会话存储）
---
### 2. **C++ SharedState 的通用实现**
#### （1）Borg 模式（Monostate）实现
```cpp
class SharedState {
private:
    static std::unordered_map<std::string, std::string> _sharedData;
    static std::mutex _mtx;
public:
    SharedState() = default;
    void set(const std::string& key, const std::string& value) {
        std::lock_guard<std::mutex> lock(_mtx);
        _sharedData[key] = value;
    }
    std::string get(const std::string& key) {
        std::lock_guard<std::mutex> lock(_mtx);
        return _sharedData[key];
    }
};
std::unordered_map<std::string, std::string> SharedState::_sharedData;
std::mutex SharedState::_mtx;
```
- 所有实例共享 `_sharedData`，任一会话修改后，其他会话立即可见。
- 通过 `std::mutex` 保证线程安全。
#### （2）单例（Singleton）模式实现
```cpp
class SharedState {
private:
    static SharedState* _instance;
    std::unordered_map<std::string, std::string> _data;
    std::mutex _mtx;
    SharedState() = default;
public:
    static SharedState& getInstance() {
        static SharedState instance;
        return instance;
    }
    void set(const std::string& key, const std::string& value) {
        std::lock_guard<std::mutex> lock(_mtx);
        _data[key] = value;
    }
    std::string get(const std::string& key) {
        std::lock_guard<std::mutex> lock(_mtx);
        return _data[key];
    }
};
```
- 全局唯一实例，适合需要严格单例的场景。
---
### 3. **为什么所有会话要使用同一状态？**
#### （1）资源效率与一致性
- **避免重复创建**：如数据库连接池、线程池等资源，每个会话独立创建会极大浪费资源。
- **状态一致性**：所有会话看到的是同一份数据，避免数据不一致。
#### （2）分布式与高可用
- 在负载均衡/集群环境下，不同服务器上的会话需要共享状态（如 Redis 存储会话），才能实现会话保持和无缝切换。
#### （3）业务需求
- 某些业务逻辑（如全局计数器、全局锁、共享缓存）天然需要全局唯一状态。
---
### 4. **为什么不能完全分开不同会话？**
#### （1）会话隔离的代价
- 每个会话独立存储状态，会导致：
  - **内存开销大**：每个会话都保存一份完整状态。
  - **数据同步困难**：不同会话之间难以共享数据。
  - **扩展性差**：集群环境下，会话切换会导致状态丢失。
#### （2）典型场景：分布式会话共享
- 用户登录后，如果请求被负载均衡到另一台服务器，若会话不共享，会导致用户重新登录。
- 常见解决方案：
  - Session 复制（Tomcat 集群）
  - Session 集中存储（Redis、Memcached）
  - JWT（无状态 Token）
---
### 5. **总结与最佳实践**
- **SharedState 适用于需要全局状态、资源复用、会话共享的场景。**
- **会话隔离适用于状态无关、无状态服务、对安全性要求极高的场景。**
- **实际项目中，常采用混合模式：**
  - 全局配置、连接池等使用 SharedState。
  - 用户敏感数据、临时状态等使用会话隔离。
---
### 6. **参考代码与扩展阅读**
- [C++ Borg 模式实现](https://blog.csdn.net/qq_215393)
- [C++ 单例模式与线程安全](https://zhuanlan.zhihu.com/p/497427434)
- [分布式会话共享方案](https://blog.csdn.net/u012829124/article/details/72831553)
---



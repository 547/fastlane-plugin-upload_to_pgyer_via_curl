
# fastlane-plugin-upload_to_pgyer_via_curl

[![Gem Version](https://img.shields.io/gem/v/fastlane-plugin-upload_to_pgyer_via_curl.svg?style=flat)](https://rubygems.org/gems/fastlane-plugin-upload_to_pgyer_via_curl)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://opensource.org/licenses/MIT)

🚀 使用 `curl` 高速上传 iOS/Android 应用到 [蒲公英 (Pgyer)](https://www.pgyer.com)。相比默认的 Ruby HTTP 客户端，**上传速度更快、更稳定**。

> 适用于需要上传大体积 IPA/APK 的团队，尤其在网络较差或需要限速的 CI 环境中表现优异。

---

## 📦 安装
> ⚠️ 确保你的系统已安装 `curl`（绝大多数 macOS/Linux 系统默认自带）。

### 确保 `Pluginfile` 正确（Bundle 管理）
进入的你的工程根目录下找到fastlane/Pluginfile文件，没有就创建一个（注意：没有后缀，就是Pluginfile）

如果你使用 `Pluginfile`（推荐），直接写：

```ruby
gem 'fastlane-plugin-upload_to_pgyer_via_curl', 
    :git => 'https://gitee.com/timersevenwang/fastlane-plugin-upload_to_pgyer_via_curl.git',
    :tag => '1.0.0'
```
或使用github的
```ruby
gem 'fastlane-plugin-upload_to_pgyer_via_curl', 
    :git => 'https://github.com/547/fastlane-plugin-upload_to_pgyer_via_curl.git',
    :tag => '1.0.0'
```

然后运行：

```bash
bundle install
```

Fastlane 会自动加载插件。

---

### 🛠️ 验证插件是否安装成功

运行：

```bash
fastlane action upload_to_pgyer_via_curl
```

如果能显示插件的帮助信息，说明安装成功 ✅

---

## 🚀 使用方法

在 `Fastfile` 中调用：

```ruby
lane :upload_to_pgyer do
  upload_to_pgyer_via_curl(
    file_path: "path/to/your/app.ipa", # 或 apk_path
    api_key: "your_pgyer_api_key",
    
    # 可选参数
    build_update_description: "本次更新内容：\n- 修复了登录闪退\n- 优化了启动速度",
    build_channel_shortcut: "test_ios_20250815",
    build_install_type: 1, # 1=公开，2=密码安装，3=扫描安装（默认1）
    
    # 高级选项
    timeout: 1800,        # 总超时时间（秒）
  )
end
```

运行：

```bash
fastlane upload_to_pgyer
```

---

## ⚙️ 参数说明

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `file_path` | String | ✅ | - | IPA 或 APK 文件路径 |
| `api_key` | String | ✅ | - | 蒲公英 API Key（在后台获取） |
| `build_update_description` | String | ❌ | - | 更新日志，支持换行 `\n` |
| `build_channel_shortcut` | String | ❌ | - | 渠道短链标识 |
| `build_install_type` | Integer | ❌ | `1` | 安装方式：1=公开，2=密码，3=扫描 |
| `timeout` | Integer | ❌ | `1800` | 整个上传最大耗时（秒） |

> 📝 提示：`build_update_description` 中的单引号 `'` 会被自动转义，无需手动处理。

---

## 💡 示例场景

### 1. 基础上传（iOS）

```ruby
upload_to_pgyer_via_curl(
  file_path: "./build/app.ipa",
  api_key: "xxxxxx",
  build_update_description: "v1.5.0 正式版发布"
)
```

### 2. 带渠道（Android）

```ruby
upload_to_pgyer_via_curl(
  apk_path: "./app-release.apk",
  api_key: "xxxxxx",
  build_channel_shortcut: "google_play",
  build_install_type: 1 # 公开安装
)
```

---

## 📚 参考文档
- [蒲公英 API 文档](https://www.pgyer.com/doc/view/api#uploadApp)
- [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) 
- [Plugins documentation](https://docs.fastlane.tools/actions/)
- [fastlane.tools](https://fastlane.tools).



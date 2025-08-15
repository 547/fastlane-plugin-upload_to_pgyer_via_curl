# Fastlane 插件开发与发布完整指南

> 📦 从零创建、调试、发布、安装 Fastlane 插件，支持发布到 RubyGems、Gitee、GitHub，适用于 iOS/Android 自动化发布场景。

---

## 🎯 目标

本文档将带你完成以下全流程：

1. ✅ 创建一个 Fastlane 插件（如 `upload_to_pgyer_via_curl`）
2. ✅ 调试与本地测试
3. ✅ 发布到 RubyGems（全球可用）
4. ✅ 发布到 Gitee / GitHub（代码托管 + Release 分发）
5. ✅ 安装插件（多种方式）

---

## 1️⃣ 创建 Fastlane 插件

### 1.1 安装 Fastlane（如果未安装）

```bash
gem install fastlane
```

### 1.2 创建插件模板

```bash
fastlane new_plugin your_plugin_name
```

> 💡 示例：`fastlane new_plugin upload_to_pgyer_via_curl`

会提示你输入：

- 插件名（如 `upload_to_pgyer_via_curl`）
- 描述（如 "Upload IPA to Pgyer using curl"）
- 作者、邮箱、GitHub 地址等

### 1.3 项目结构

创建后生成如下目录：

```
fastlane-plugin-your_plugin_name/
├── fastlane-plugin-your_plugin_name.gemspec
├── lib/
│   └── fastlane/
│       └── plugin/
│           └── your_plugin_name/
│               ├── actions/
│               │   └── your_plugin_name.rb   ← 核心逻辑
│               ├── helper/
│               │   └── your_plugin_name_helper.rb
│               └── version.rb
├── spec/                         ← 测试用例
└── README.md
```

### 1.4 编写插件逻辑

编辑 `lib/fastlane/plugin/your_plugin_name/actions/your_plugin_name.rb`

示例骨架：

```ruby
module Fastlane
  module Actions
    class UploadToPgyerViaCurlAction < Action
      def self.run(params)
        UI.message("🚀 开始上传到蒲公英...")

        # 你的 curl 上传逻辑
        command = "curl -F file=@#{params[:ipa_path]} ... https://www.pgyer.com/apiv2/app/upload"
        sh(command)

        UI.success("✅ 上传成功！")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :ipa_path,
                                       env_name: "PGYER_IPA_PATH",
                                       description: "IPA 文件路径",
                                       verify_block: proc do |value|
                                         UI.user_error!("🚫 IPA 文件不存在") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :api_key,
                                       env_name: "PGYER_API_KEY",
                                       description: "蒲公英 API Key",
                                       sensitive: true)
        ]
      end

      def self.description
        "使用 curl 上传 IPA 到蒲公英"
      end

      def self.details
        "相比 Ruby HTTP 客户端，curl 上传更稳定、更快，支持限速、超时等高级功能。"
      end

      def self.author
        "momo"
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
```

---

## 2️⃣ 调试与本地测试

### 2.1 在目标项目中测试

进入你的 iOS/Android 项目目录：

```bash
cd /path/to/your/app
```

### 2.2 本地打包插件

回到插件目录，打包 gem：

```bash
cd /path/to/fastlane-plugin-your_plugin_name
gem build fastlane-plugin-your_plugin_name.gemspec
```

生成文件：`fastlane-plugin-your_plugin_name-1.0.0.gem`

### 2.3 安装本地插件

```bash
cd /path/to/your/app
fastlane add_plugin /path/to/fastlane-plugin-your_plugin_name-1.0.0.gem
```

### 2.4 在 `Fastfile` 中使用

```ruby
lane :beta do
  your_plugin_name(
    ipa_path: "build/app.ipa",
    api_key: "your_api_key"
  )
end
```

运行测试：

```bash
fastlane beta
```

---

## 3️⃣ 发布插件到 RubyGems

> ⚠️ 需要注册 [https://rubygems.org](https://rubygems.org) 并开启 MFA。

### 3.1 登录 RubyGems

```bash
gem signin
# 输入邮箱和密码
```

### 3.2 开启 MFA（必须）

1. 登录 [https://rubygems.org](https://rubygems.org)
2. 进入 **Account Settings**
3. 启用 **Multi-Factor Authentication**（推荐 TOTP，如 Authy）
4. 保存恢复码

### 3.3 打包并发布

```bash
# 更新版本号
# 修改 lib/fastlane/plugin/your_plugin_name/version.rb

# 打包
gem build fastlane-plugin-your_plugin_name.gemspec

# 发布
gem push fastlane-plugin-your_plugin_name-1.0.0.gem
```

发布成功后，全球用户可通过：

```bash
fastlane add_plugin your_plugin_name
```

安装使用。

---

## 4️⃣ 发布到 Gitee 和 GitHub

### 4.1 初始化 Git

```bash
git init
git add .
git commit -m "feat: initial commit"
```

### 4.2 添加远程仓库

```bash
# 添加 GitHub
git remote add github https://github.com/your_username/your_repo.git

# 添加 Gitee
git remote add gitee https://gitee.com/your_username/your_repo.git
```

### 4.3 推送代码

```bash
git push -u github main
git push -u gitee main
```

### 4.4 创建标签

```bash
git tag v1.0.0
git push github v1.0.0
git push gitee v1.0.0
```

---

## 5️⃣ 自动发布 Release（含 .gem 文件）

### 5.1 使用 GitHub CLI（推荐）

安装：

```bash
brew install gh
gh auth login
```

发布：

```bash
gh release create v1.0.0 \
  --title "v1.0.0 - Initial Release" \
  --notes "🚀 First release with curl upload support" \
  fastlane-plugin-your_plugin_name-1.0.0.gem
```

### 5.2 使用 Gitee API（curl）

```bash
TOKEN="your_gitee_token"
OWNER="your_username"
REPO="your_repo"
TAG="v1.0.0"
GEM_FILE="fastlane-plugin-your_plugin_name-1.0.0.gem"

# 创建 Release
UPLOAD_URL=$(curl -X POST \
  "https://gitee.com/api/v5/repos/$OWNER/$REPO/releases" \
  -H "Content-Type: application/json" \
  -d "{\"tag_name\":\"$TAG\",\"name\":\"Release $TAG\",\"body\":\"Automated release\"}" \
  -d "access_token=$TOKEN" | grep -o '"upload_url":"[^"]*"' | cut -d'"' -f4)

# 上传 .gem 文件
curl -X POST "$UPLOAD_URL?access_token=$TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@$GEM_FILE"
```

---

## 6️⃣ 安装插件（多种方式）

| 方式 | 命令 | 说明 |
|------|------|------|
| **RubyGems** | `fastlane add_plugin your_plugin_name` | 最简单，推荐 |
| **Gitee Release** | `fastlane add_plugin https://gitee.com/.../your_plugin_name-1.0.0.gem` | 国内快，需先 `gem install` |
| **GitHub Release** | `fastlane add_plugin https://github.com/.../your_plugin_name-1.0.0.gem` | 国际用户 |
| **Git 仓库** | `add_plugin git: 'https://gitee.com/...git', tag: 'v1.0.0'` | 支持分支/标签 |
| **Pluginfile** | `gem 'fastlane-plugin-your_plugin_name', git: 'https://gitee.com/...git', tag: 'v1.0.0'` | 最稳定，适合团队 |

> ⚠️ 注意：直接使用 URL 安装有时会报错 `Plugin name must not contain '-'`，建议先 `gem install URL` 再 `add_plugin name`。

---

## 7️⃣ 推荐工作流（一键发布脚本）

创建 `release.sh`：

```bash
#!/bin/bash

VERSION="v$(grep -oE 'VERSION = "[^"]+"' lib/fastlane/plugin/*/version.rb | cut -d'"' -f2)"
GEM_NAME=$(ls *.gemspec | sed 's/.gemspec//')

echo "🚀 发布 $VERSION"

gem build $GEM_NAME.gemspec
gem install ${GEM_NAME}-*.gem

git add .
git commit -m "chore: release $VERSION"
git tag $VERSION

git push origin main --tags
git push gitee main --tags

gh release create $VERSION --title "Release $VERSION" ${GEM_NAME}-*.gem

echo "✅ 发布完成！"
```

运行：

```bash
chmod +x release.sh
./release.sh
```

---

## 📚 参考文档

- [Fastlane Plugins Guide](https://docs.fastlane.tools/plugins/create-plugin/)
- [RubyGems Guides](https://guides.rubygems.org/)
- [GitHub CLI](https://cli.github.com/)
- [Gitee API 文档](https://gitee.com/api/v5/swagger)

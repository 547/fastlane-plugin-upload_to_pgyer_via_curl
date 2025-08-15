# encoding: utf-8
require 'json'
require 'fastlane/action'

module Fastlane
  module Actions
    # 使用 curl 命令行工具上传 IPA/APK 到蒲公英 (www.pgyer.com)
    # 解决 fastlane-plugin-pgyer 上传大文件慢的问题（Ruby multipart-post 性能差）
    #
    # 优势：
    # - 上传速度快（使用系统 curl，可达 5~10 MB/s）
    # - 支持所有蒲公英 v2 API 参数
    # - 输出下载链接和二维码
    # - 可复用，适合多 lane 调用
    #
    # 注意：
    # - 必须提供 `file_path` 和 `api_key`
    # - file_path：(必填) 需要上传的ipa或者apk文件
    # - api_key：(必填) API Key（注意：字段名为 _api_key）（https://www.pgyer.com/doc/view/api#auth）
    # - build_install_type：(选填)应用安装方式，值为(1,2,3，默认为1 公开安装)。1：公开安装，2：密码安装，3：邀请安装
    # - 推荐将敏感信息（如 key）配置在 .env 或 CI 环境变量中
    class UploadToPgyerViaCurlAction < Action
      # 主要执行方法
      def self.run(params)
        # 提取参数
        file_path = params[:file_path]
        api_key = params[:api_key]
        update_description = params[:update_description]
        channel = params[:channel]
        build_install_type = params[:build_install_type] || 1
        build_password = params[:build_password]
        build_update_description = params[:build_update_description] || update_description
        build_install_date = params[:build_install_date]
        build_install_start_date = params[:build_install_start_date]
        build_install_end_date = params[:build_install_end_date]
        build_channel_shortcut = params[:build_channel_shortcut] || channel
        timeout = params[:timeout] || 1800  # 默认超时时间为 30 分钟

        # 1. 检查 IPA 文件是否存在
        unless File.exist?(file_path)
          UI.user_error!("❌ 文件不存在：#{file_path}")
        end
        size_mb = File.size(file_path).to_f / 1024 / 1024
        UI.message("📦 文件大小: #{size_mb.round(2)} MB")

        # 2. 构建 curl 命令
        command = [
          "timeout", timeout.to_s,
          "curl",
          "-#",                            # 显示简洁进度条（推荐）
          "-w", "\\n%{http_code}",         # 在响应末尾追加 HTTP 状态码
          "-F", "file=@#{file_path}",
          "-F", "_api_key=#{api_key}",
          "-F", "buildInstallType=#{build_install_type}"
        ]

        # 添加可选参数（仅当值存在时）
        if build_update_description.to_s.strip.length > 0
          escaped_desc = escape_single_quote(build_update_description)
          command += ["-F", "buildUpdateDescription='#{escaped_desc}'"]
        end
        command += ["-F", "buildPassword=#{build_password}"] if build_password.to_s.strip.length > 0
        command += ["-F", "buildInstallDate=#{build_install_date}"] if build_install_date
        command += ["-F", "buildInstallStartDate=#{build_install_start_date}"] if build_install_start_date.to_s.strip.length > 0
        command += ["-F", "buildInstallEndDate=#{build_install_end_date}"] if build_install_end_date.to_s.strip.length > 0
        command += ["-F", "buildChannelShortcut=#{build_channel_shortcut}"] if build_channel_shortcut.to_s.strip.length > 0

        # 限制最大速率，避免被服务器限流
        command << "--limit-rate" << "200M"

        # 目标 URL
        command << "https://www.pgyer.com/apiv2/app/upload"

        # 输出调试信息（仅在 verbose 模式下）
        UI.verbose("🔧 执行命令: #{command.join(' ')}")

        # 3. 执行命令（兼容 Fastlane 2.227.1 的正确方式）
        UI.message("🚀 正在使用 curl 上传到蒲公英...")

        # 临时保存原始环境变量
        original_output = ENV['FASTLANE_DISABLE_OUTPUT']
        original_colors = ENV['FASTLANE_DISABLE_COLORS']

        begin
          # 👇 关键：临时禁用 Fastlane 的输出捕获
          ENV['FASTLANE_DISABLE_OUTPUT'] = '1'
          ENV['FASTLANE_DISABLE_COLORS'] = '1'  # 可选：减少 ANSI 色彩干扰

          # 执行命令（此时输出不会被 Ruby 缓冲，直接打印到终端）
          result = sh(command)

          # 检查退出码
          unless $?.success?
            UI.error("❌ curl 命令执行失败 (退出码: #{$?.exitstatus})")
            raise "curl 执行失败"
          end

          # 解析输出：最后一行是 HTTP 状态码
          lines = result.strip.split("\n")
          status_code = lines.pop.to_i
          body = lines.join("\n")

          # 4. 解析 JSON 响应
          json = JSON.parse(body)

          if status_code == 200 && json["code"] == 0
            download_url = "https://www.pgyer.com/#{json['data']['buildShortcutUrl']}"
            qr_url = json['data']['buildQRCodeURL']

            UI.success("🎉 上传成功！")
            UI.message("🔗 下载地址: #{download_url}")
            UI.message("📱 二维码: #{qr_url}")

            return {
              success: true,
              download_url: download_url,
              qr_url: qr_url,
              build_qrcode: qr_url,
              build_short_url: json['data']['buildShortcutUrl'],
              json: json
            }
          else
            error_msg = json["message"] || "未知错误"
            UI.error("蒲公英返回错误: #{error_msg} (HTTP #{status_code})")
            raise "蒲公英上传失败: #{error_msg}"
          end

        rescue => e
          UI.error("上传失败: #{e.message}")
          raise e
        ensure
          # 👇 恢复原始环境变量
          ENV['FASTLANE_DISABLE_OUTPUT'] = original_output
          ENV['FASTLANE_DISABLE_COLORS'] = original_colors
        end
      end
      # Shellwords.escape包裹多行字符串会导致字符串中出现大量 \ 转义符，
      # 同时会导致curl 在解析这种每个字符都被反斜杠转义的字符串时，性能急剧下降，
      # 因为它要逐字符解析，无法高效处理，从而导致上传速度极慢。
      #	改用 '#{...}' 包裹多行字符串，就会变得快、简洁、标准，缺点是只处理单引号
      def self.escape_single_quote(str)
        str.gsub("'", "'\\''")
      end
      # 描述这个 action 的用途
      def self.description
        "使用 curl 上传 IPA/APK 到蒲公英 (www.pgyer.com)，解决 fastlane-plugin-pgyer 上传慢的问题"
      end

      # 作者信息(作者名字或团队名)
      def self.authors
        ["timer_sevenwang@163.com"]
      end

      # 返回值说明
      def self.return_value
        "返回一个 Hash，包含 :download_url, :qr_url, :build_short_url, :json 等字段"
      end

      # 详细说明
      def self.details
        <<~DOCS
          使用系统 `curl` 命令上传应用到蒲公英，性能远高于 Ruby 实现的 multipart-post。
          支持蒲公英 v2 API（旧版接口：https://www.pgyer.com/apiv2/app/upload）  所有常见参数，包括密码安装、有效期、渠道短链等。
          蒲公英官方文档：https://www.pgyer.com/doc/view/api#fastUploadApp
        DOCS
      end

      # 支持的参数列表
      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :file_path,
            env_name: "PGYER_FILE_PATH",
            description: "(必填) IPA 或 APK 文件的本地路径",
            is_string: true,
            verify_block: proc do |value|
              UI.user_error!("❌ IPA 文件不存在: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :api_key,
            env_name: "PGYER_API_KEY",
            description: "(必填) 蒲公英 API Key（可进：https://www.pgyer.com/doc/view/api#auth 查看）",
            is_string: true,
            verify_block: proc do |value|
              UI.user_error!("❌ 缺少 _api_key") if value.to_s.strip.length == 0
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :update_description,
            env_name: "PGYER_UPDATE_DESCRIPTION",
            description: "版本更新描述（旧字段，建议使用 build_update_description）",
            is_string: true,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :channel,
            env_name: "PGYER_CHANNEL",
            description: "渠道短链（旧字段，建议使用 build_channel_shortcut）",
            is_string: true,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_install_type,
            env_name: "PGYER_BUILD_INSTALL_TYPE",
            description: "安装方式：1=公开安装, 2=密码安装, 3=邀请安装",
            is_string: false,
            default_value: 1,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_password,
            env_name: "PGYER_BUILD_PASSWORD",
            description: "设置安装密码（仅当 buildInstallType=2 时有效）",
            is_string: true,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_update_description,
            env_name: "PGYER_BUILD_UPDATE_DESCRIPTION",
            description: "版本更新描述（推荐使用此字段）",
            is_string: true,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_install_date,
            env_name: "PGYER_BUILD_INSTALL_DATE",
            description: "是否设置安装有效期（1=是, 0=否）",
            is_string: false,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_install_start_date,
            env_name: "PGYER_BUILD_INSTALL_START_DATE",
            description: "安装有效期开始时间（格式：YYYY-MM-DD）",
            is_string: true,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_install_end_date,
            env_name: "PGYER_BUILD_INSTALL_END_DATE",
            description: "安装有效期结束时间（格式：YYYY-MM-DD）",
            is_string: true,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :build_channel_shortcut,
            env_name: "PGYER_BUILD_CHANNEL_SHORTCUT",
            description: "指定渠道的下载短链接",
            is_string: true,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :timeout,
            env_name: "PGYER_TIMEOUT",
            description: "上传超时时间（秒），默认为 1800 秒（30 分钟）",
            is_string: false,
            default_value: 1800,
            optional: true
          )
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end

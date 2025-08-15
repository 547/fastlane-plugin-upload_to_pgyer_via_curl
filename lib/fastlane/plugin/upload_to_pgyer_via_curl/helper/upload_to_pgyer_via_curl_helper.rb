require 'fastlane_core/ui/ui'
require 'open3'
module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class UploadToPgyerViaCurlHelper
      def self.execute_command(command)
        UI.message("🔧 执行命令: #{command.join(' ')}")

        begin
          stdout, stderr, status = Open3.capture3(*command)

          if status.success?
            return stdout
          else
            UI.error("❌ curl 执行失败 (退出码: #{status.exitstatus})")
            UI.error("➡️  命令: #{command.join(' ')}")
            UI.error("📝 错误信息: #{stderr.strip}")
            raise "curl 命令执行失败"
          end
        rescue => e
          UI.crash!("💥 执行命令时发生错误: #{e.message}")
        end
      end
    end
  end
end

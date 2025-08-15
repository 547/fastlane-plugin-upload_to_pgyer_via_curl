lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/upload_to_pgyer_via_curl/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-upload_to_pgyer_via_curl'
  spec.version       = Fastlane::UploadToPgyerViaCurl::VERSION
  spec.author        = 'timer_sevenwang'
  spec.email         = 'timer_sevenwang@163.com'

  spec.summary       = '使用系统 `curl` 命令上传应用到蒲公英，性能远高于 Ruby 实现的 multipart-post。'
  spec.homepage      = "https://github.com/547/fastlane-plugin-upload_to_pgyer_via_curl"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 2.6'

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'
end

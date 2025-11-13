require_relative "boot"
require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ShopifyRails
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # 設定時區為台灣時間
    config.time_zone = 'Asia/Taipei'
    config.active_record.default_timezone = :local

    # 設定 API 模式（如果只做 API 的話可以啟用）
    # config.api_only = true

    # 多租戶相關設定
    # 設定 acts_as_tenant 的 require_tenant 為 false，允許在沒有 tenant 的情況下也能運作
    config.acts_as_tenant_require_tenant = false
  end
end


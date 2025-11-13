# 跨域資源共享設定
# 允許前端應用程式從不同域名存取 API

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 允許的來源域名（根據實際需求修改）
    origins '*'
    
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
end


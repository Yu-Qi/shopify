# acts_as_tenant 設定
# 設定多租戶的預設行為

ActsAsTenant.configure do |config|
  # 是否要求必須有 tenant（設為 false 允許在沒有 tenant 時也能運作）
  config.require_tenant = false
end


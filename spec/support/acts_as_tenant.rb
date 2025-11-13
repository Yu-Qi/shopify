RSpec.configure do |config|
  config.before do
    ActsAsTenant.current_tenant = nil
  end

  config.after do
    ActsAsTenant.current_tenant = nil
  end
end


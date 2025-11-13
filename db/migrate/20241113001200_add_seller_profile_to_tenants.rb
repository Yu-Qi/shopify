class AddSellerProfileToTenants < ActiveRecord::Migration[7.1]
  def up
    add_reference :tenants, :seller_profile, foreign_key: true

    migration_user = Class.new(ActiveRecord::Base) do
      self.table_name = 'users'
    end
    migration_seller_profile = Class.new(ActiveRecord::Base) do
      self.table_name = 'seller_profiles'
    end
    migration_tenant = Class.new(ActiveRecord::Base) do
      self.table_name = 'tenants'
    end

    migration_tenant.reset_column_information

    migration_tenant.find_each do |tenant|
      next unless tenant[:user_id]

      user = migration_user.find(tenant[:user_id])
      seller_profile = migration_seller_profile.find_by(user_id: user.id)
      seller_profile ||= migration_seller_profile.create!(
        user_id: user.id,
        display_name: user[:name]
      )

      tenant.update_column(:seller_profile_id, seller_profile.id)
    end

    change_column_null :tenants, :seller_profile_id, false
    remove_reference :tenants, :user, foreign_key: true
  end

  def down
    add_reference :tenants, :user, foreign_key: true

    migration_tenant = Class.new(ActiveRecord::Base) do
      self.table_name = 'tenants'
    end
    migration_seller_profile = Class.new(ActiveRecord::Base) do
      self.table_name = 'seller_profiles'
    end

    migration_tenant.reset_column_information

    migration_tenant.find_each do |tenant|
      next unless tenant[:seller_profile_id]

      seller_profile = migration_seller_profile.find_by(id: tenant[:seller_profile_id])
      tenant.update_column(:user_id, seller_profile[:user_id]) if seller_profile
    end

    change_column_null :tenants, :user_id, false
    remove_reference :tenants, :seller_profile, foreign_key: true
  end
end


module FastAdminRails
  # 在引擎中不依赖宿主的 ApplicationRecord，直接继承 ActiveRecord::Base
  class User < ::ActiveRecord::Base
    self.table_name = "fast_admin_users"

    has_secure_password

    validates :email, presence: true, uniqueness: true
    validates :password, presence: true, on: :create

    validates :nickname, length: { maximum: 100 }, allow_nil: true
  end
end

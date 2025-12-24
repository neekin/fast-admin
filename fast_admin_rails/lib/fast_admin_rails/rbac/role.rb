module FastAdminRails
  class Role < ::ActiveRecord::Base
    self.table_name = "fa_roles"

    has_many :role_permissions, class_name: "FastAdminRails::RolePermission", dependent: :destroy
    has_many :permissions, through: :role_permissions, class_name: "FastAdminRails::Permission"
    has_many :user_roles, class_name: "FastAdminRails::UserRole", dependent: :destroy

    validates :key, presence: true, uniqueness: true
    validates :name, presence: true
  end
end

module FastAdminRails
  class Permission < ::ActiveRecord::Base
    self.table_name = "fa_permissions"

    has_many :role_permissions, class_name: "FastAdminRails::RolePermission", dependent: :destroy
    has_many :roles, through: :role_permissions, class_name: "FastAdminRails::Role"

    validates :code, presence: true, uniqueness: true
    validates :name, presence: true
  end
end

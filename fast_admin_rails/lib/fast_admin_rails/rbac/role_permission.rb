module FastAdminRails
  class RolePermission < ::ActiveRecord::Base
    self.table_name = "fa_role_permissions"

    belongs_to :role, class_name: "FastAdminRails::Role"
    belongs_to :permission, class_name: "FastAdminRails::Permission"

    validates :role_id, presence: true
    validates :permission_id, presence: true
  end
end

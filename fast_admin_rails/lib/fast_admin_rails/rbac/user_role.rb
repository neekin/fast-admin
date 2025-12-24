module FastAdminRails
  class UserRole < ::ActiveRecord::Base
    self.table_name = "fa_user_roles"

    belongs_to :role, class_name: "FastAdminRails::Role"

    # user_id 引用宿主或引擎用户表的 ID；不建立外键以适配宿主替换
    validates :user_id, presence: true
  end
end

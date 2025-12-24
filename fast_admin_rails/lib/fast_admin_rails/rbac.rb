module FastAdminRails
  module RBAC
    # 检查用户是否拥有指定权限码
    def self.allowed?(user, code)
      return false if user.nil?
      perm = FastAdminRails::Permission.find_by(code: code)
      return false unless perm
      # 用户 -> 角色 -> 权限
      role_ids = FastAdminRails::UserRole.where(user_id: user.id).pluck(:role_id)
      return false if role_ids.empty?
      FastAdminRails::RolePermission.where(role_id: role_ids, permission_id: perm.id).exists?
    rescue
      false
    end

    # 便捷授予与撤销（供管理端使用）
    def self.grant_role(user_id, role_key)
      role = FastAdminRails::Role.find_by(key: role_key)
      return false unless role
      FastAdminRails::UserRole.find_or_create_by(user_id: user_id, role_id: role.id)
      true
    end

    def self.revoke_role(user_id, role_key)
      role = FastAdminRails::Role.find_by(key: role_key)
      return false unless role
      FastAdminRails::UserRole.where(user_id: user_id, role_id: role.id).delete_all
      true
    end
  end
end

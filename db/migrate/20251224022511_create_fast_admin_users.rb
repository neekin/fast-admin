class CreateFastAdminUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :fast_admin_users do |t|
      t.string :email, null: false
      t.string :nickname
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :fast_admin_users, :email, unique: true
  end
end

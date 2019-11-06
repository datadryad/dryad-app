class CopyTenantIdToeResource < ActiveRecord::Migration
  def change
    # set any unmatched to ucop
    update_stmt = <<-SQL
      UPDATE stash_engine_resources res
      LEFT JOIN stash_engine_users user
      ON res.`user_id` = user.id
      SET res.tenant_id = 'ucop'
      WHERE user.tenant_id is NULL;
    SQL
    execute update_stmt.squish

    # otherwise set the tenant in the resource to the owner's tenant
    update_stmt = <<-SQL
      UPDATE stash_engine_resources res
      JOIN stash_engine_users user
      ON res.`user_id` = user.id
      SET res.tenant_id = user.tenant_id;
    SQL
    execute update_stmt.squish
  end
end

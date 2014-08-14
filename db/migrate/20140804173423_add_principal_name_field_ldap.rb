class AddPrincipalNameFieldLdap < ActiveRecord::Migration
  def up
    add_column :sites, :ldap_principal_name_field, :string
  end

  def down
    remove_column :sites, :ldap_principal_name_field
  end
end

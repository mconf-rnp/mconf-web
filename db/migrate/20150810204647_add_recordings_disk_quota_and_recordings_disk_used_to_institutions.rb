class AddRecordingsDiskQuotaAndRecordingsDiskUsedToInstitutions < ActiveRecord::Migration
  def change
    add_column :institutions, :recordings_disk_used, :string, default: 0
    add_column :institutions, :recordings_disk_quota, :string, default: 0
  end
end

class ChangeInstitutionRecordingQuotasToBigInt < ActiveRecord::Migration
  def change
    change_column :institutions, :recordings_disk_used,  :bigint, default: 0
    change_column :institutions, :recordings_disk_quota, :bigint, default: 0
  end
end

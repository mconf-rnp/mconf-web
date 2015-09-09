module UpdateInstitutionRecordingsDisk
  extend ActiveSupport::Concern

  included do
    after_save :find_institution_and_update
    after_destroy :find_institution_and_update
  end

  def find_institution_and_update
    if self.room.present?
      space_or_user = self.room.owner

      # Some user don't have institutions, tipically admins so this method could fail
      if space_or_user.present?
        space_or_user.institution.try(:update_recordings_disk_used!)
      end
    end
  end
end

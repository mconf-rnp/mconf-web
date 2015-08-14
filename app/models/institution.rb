class Institution < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  validates :user_limit, :numericality => true, :allow_blank => true
  validates :can_record_limit, :numericality => true, :allow_blank => true

  has_many :permissions, -> { where(:subject_type => 'Institution') },
           :foreign_key => "subject_id", :dependent => :destroy

  has_many :users, :through => :permissions

  has_many :spaces

  extend FriendlyId
  friendly_id :name, :use => :slugged, :slug_column => :permalink

  validates :permalink, :presence => true

  before_validation :adjust_recordings_disk_quota

  def self.roles
    ['User', 'Admin'].map { |r| Role.find_by_name(r) }
  end

  # Search by both name and acronym
  def self.search name
    # Return some institutions on blank search
    return Institution.first(3) if name.blank?
    where "name LIKE :name OR acronym LIKE :name", :name => "%#{name}%"
  end

  # Sends all users from the 'duplicate' institution to the 'original' and deletes the duplicate
  # Useful in cases where users have joined a duplicate institution by mistake
  def self.correct_duplicate original, duplicate
    duplicate.permissions.each do |p|
      p.subject_id = original.id
      p.save!
    end
    duplicate.reload.destroy
  end

  def self.find_or_create_by_name_or_acronym name
    # Try to find institution by acronym then by name
    i   = find_by_acronym(name)
    i ||= find_by_name(name)

    # Create the institution if it doesn't exist and add the user to it
    i ||= create(:name => name)
  end

  def approved_users
    users.where :approved => true
  end

  def full?
    !user_limit.blank? && (approved_users.count >= user_limit)
  end

  def users_that_can_record
    approved_users.where :can_record => true
  end

  def can_record_full?
    !can_record_limit.nil? && (users_that_can_record.count >= can_record_limit)
  end

  def admins
    permissions.where(:role_id => Role.find_by_name('Admin').id).map(&:user)
  end

  def add_member! u, role = 'User'
    # Adds the user to the institution and sets his role as `role`
    p = Permission.where(:user_id => u.id, :subject_type => 'Institution').first
    p ||= Permission.new :user => u
    p.subject = self
    p.role = Role.find_by_name(role)
    p.save!
  end

  def remove_member! u, role = 'User'
    p = Permission.where(:user_id => u.id, :subject_type => 'Institution').first
    p.destroy unless p.nil?
  end

  def unapproved_users
    users.where :approved => [nil, false]
  end

  def to_json
    { text: full_name, id: id, permalink: permalink}
  end

  def full_name
    n = name
    n += " (#{acronym})" unless acronym.blank?
    n
  end

  def user_role user
    p = Permission.where(:user_id => user.id, :subject_type => 'Institution').first
    p.role.name unless p.nil? or p.role.nil?
  end

  # Call this to query all recordings belonging to this institution (users and spaces)
  # and get a sum of their sizes in the 'recordings_disk_used' field
  def update_recordings_disk_used!
    room_ids = BigbluebuttonRoom.where(owner_id: spaces.with_disabled.ids, owner_type: 'Space').ids |
            BigbluebuttonRoom.where(owner_id: users.with_disabled.ids, owner_type: 'User').ids

    recordings = BigbluebuttonRecording.where(room_id: room_ids).published()
    update_attribute(:recordings_disk_used, recordings.sum(:size))
  end

  def exceeded_disk_quota?
    recordings_disk_used.to_i >= recordings_disk_quota.to_i
  end

  private

  def adjust_recordings_disk_quota
    if recordings_disk_quota_changed?

      if is_number?(self.recordings_disk_quota)
        # express size in bytes if a number without units was present
        write_attribute(:recordings_disk_quota, Filesize.from("#{self.recordings_disk_quota} B").to_i)
      elsif is_filesize?(self.recordings_disk_quota)
        write_attribute(:recordings_disk_quota, Filesize.from(self.recordings_disk_quota).to_i)
      end
    end
  end

  def is_number? n
    Float(n) rescue nil
  end

  def is_filesize? n
    Filesize.parse(n)[:type].present?
  end

end

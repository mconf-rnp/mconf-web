class Institution < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  validates :user_limit, :numericality => true, :allow_blank => true
  validates :can_record_limit, :numericality => true, :allow_blank => true

  has_many :permissions, -> { where(:subject_type => 'Institution') },
           :foreign_key => "subject_id", :dependent => :destroy

  has_many :users, :through => :permissions

  has_and_belongs_to_many :admins, -> {
    Permission.where(
      permissions: { subject_type: 'Institution', role_id: Role.find_by_name('Admin') }
    )
  }, join_table: :permissions, class_name: "User", foreign_key: "subject_id"

  has_many :spaces

  extend FriendlyId
  friendly_id :name, :use => :slugged, :slug_column => :permalink

  validates :permalink, :presence => true

  after_initialize :init
  before_validation :validate_and_adjust_recordings_disk_quota

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
    size = self.recordings.where(published: true, available: true).sum(:size)
    update_attribute(:recordings_disk_used, size)
  end

  # Simple method to see if the recordings size exceeded the quota
  # Don't treat this as an exact limit, because it will likely be exceeded
  # by the last recording before the quota is still valid
  def exceeded_disk_quota?
    return false if recordings_disk_quota.to_i == 0 # quota == 0 means unlimited

    recordings_disk_used.to_i >= recordings_disk_quota.to_i
  end

  # Returns a number ideally between 0..1 describing the
  # disk usage ratio for the institution
  # Could be > 1 if one big recording broke limit
  # If the quota is unlimited (0) this value is also 0 but should be irrelevant
  def disk_usage_ratio
    return 0 if recordings_disk_quota.to_i == 0

    recordings_disk_used.to_f / recordings_disk_quota.to_f
  end

  # Returns all the recordings associated with this institution.
  def recordings
    room_ids = BigbluebuttonRoom.where(owner_id: spaces.with_disabled.ids, owner_type: 'Space').ids |
               BigbluebuttonRoom.where(owner_id: users.with_disabled.ids, owner_type: 'User').ids
    BigbluebuttonRecording.where(room_id: room_ids)
  end

  attr_accessor :recordings_disk_quota_human

  private

  def init
    if self.new_record?
      self[:secret] ||= random_secret
    end
  end

  def validate_and_adjust_recordings_disk_quota
    if !recordings_disk_quota_human.nil?
      if self.recordings_disk_quota_human.blank?
        write_attribute(:recordings_disk_quota, nil)
      else
        value = Mconf::Filesize.convert(self.recordings_disk_quota_human)
        if value.nil?
          self.errors.add(:recordings_disk_quota_human, :invalid)
        else
          write_attribute(:recordings_disk_quota, value)
        end
      end
    end
  end

  def is_number? n
    Float(n) rescue nil
  end

  def is_filesize? n
    Filesize.parse(n)[:type].present?
  end

  def random_secret(length=32)
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    text = ""
    length.times do
      pos = (rand() * chars.length).floor
      text += chars[pos]
    end
    text
  end

end

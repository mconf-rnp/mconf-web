class Institution < ActiveRecord::Base
  attr_accessible :acronym, :name, :user_limit

  validates :name, :presence => true, :uniqueness => true

  validates :user_limit, :numericality => true, :allow_blank => true

  has_many :permissions, :foreign_key => "subject_id",
           :conditions => { :permissions => {:subject_type => 'Institution'} },
           :dependent => :destroy

  has_many :users, :through => :permissions

  has_many :spaces

  extend FriendlyId
  friendly_id :name, :use => :slugged, :slug_column => :permalink

  validates :permalink, :presence => true

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
      original.permissions.create(:user_id => p.user_id, :role_id => p.role_id)
    end
    duplicate.destroy
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
    !user_limit.nil? && approved_users.count >= user_limit
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
    { :text => full_name, :id => name}
  end

  def full_name
    "#{name} (#{acronym})"
  end

  def user_role user
    p = Permission.where(:user_id => user.id, :subject_type => 'Institution').first
    p.role.name unless p.nil? or p.role.nil?
  end

end

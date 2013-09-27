class Institution < ActiveRecord::Base
  attr_accessible :acronym, :name

  validates :name, :presence => true, :uniqueness => true

  has_many :permissions, :foreign_key => "subject_id",
           :conditions => { :permissions => {:subject_type => 'Institution'} },
           :dependent => :destroy

  has_many :users, :through => :permissions

  extend FriendlyId
  friendly_id :name, :use => :slugged, :slug_column => :permalink

  validates :permalink, :presence => true

  # Search by both name and acronym
  def self.search name
    return [] if name.blank?
    where "name LIKE :name OR acronym LIKE :name", :name => "%#{name}%"
  end

  # Sends all users from the 'duplicate' institution to the 'original' and deletes the duplicate
  # Useful in cases where users have joined a duplicate institution by mistake
  def self.correct_duplicate original, duplicate
    duplicate.permissions.each do |p|
      p.subject = original
      p.save!
    end
    duplicate.destroy
  end

  def admins
    permissions.where(:role_id => Role.find_by_name('Admin').id).map(&:user)
  end

  def add_admin! u
    # Adds the user to the institution and sets his role as admin
    p = Permission.where(:user_id => u.id, :subject_type => 'Institution').first
    p ||= Permission.new :user_id => u.id
    p.subject = self
    p.role = Role.find_by_name('Admin')
    p.save!
  end

  def to_json
    { :name => "#{name} (#{acronym})", :id => name}
  end

end

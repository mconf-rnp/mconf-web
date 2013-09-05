class Institution < ActiveRecord::Base
  attr_accessible :acronym, :name

  validates :name, :presence => true

  has_many :permissions, :foreign_key => "subject_id",
           :conditions => { :permissions => {:subject_type => 'Institution'} }

  has_many :users, :through => :permissions

  extend FriendlyId
  friendly_id :name, :use => :slugged, :slug_column => :permalink
end

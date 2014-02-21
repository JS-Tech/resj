class User < ActiveRecord::Base
	attr_accessor :current_password

	has_secure_password({ validations: false })

  belongs_to :user_type
  has_many :card_verifications, dependent: :destroy
  has_many :cards, through: :card_verifications
  has_many :ownerships
  has_many :parents
  has_many :users, through: :parents
  has_many :verificator_comments
  has_many :activities
  has_one :orator

  accepts_nested_attributes_for :orator

  before_save :format, :create_remember_token
  before_create :assign_gravatar

  with_options unless: :is_group? do |user|
    user.validates :firstname, presence: true, length: { maximum: 15 }
    user.validates :lastname, presence: true, length: { maximum: 15 }
    user.validates :email, :format => { :with => /\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/ }, uniqueness: true
    user.validates :gravatar_email, :format => { :with => /\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/ }, on: :update?
    user.validates :password, presence: true, length: { minimum: 5 }, confirmation: true
    user.validate :match_current_password
  end

  def send_password_reset
    self.reset_token =  SecureRandom.urlsafe_base64
    self.reset_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver
  end

  def full_name
    "#{firstname} #{lastname}"
  end

  private

  # Control by an update if the current_password is right
  def match_current_password
    if current_password && !self.authenticate(current_password)
  		errors.add(:current_password, "does not match password")
    end
  end

  # Remove spaces and capitales
  def format
    self.email.try(:strip!)
    self.email.try(:downcase!)
    self.firstname.try(:strip!)
    self.lastname.try(:strip!)
  end

  def create_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
  end

  def assign_gravatar
    self.gravatar_email = self.email
  end

  def is_group?
    user_type_id == UserType.find_by_name('group').id
  end
end

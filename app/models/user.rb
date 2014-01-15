class User < ActiveRecord::Base
	attr_accessor :current_password

	has_secure_password({ validations: false })

  belongs_to :user_type
  has_many :card_verifications
  has_many :cards, through: :card_verifications
  has_many :ownerships
  has_many :parents
  has_many :users, through: :parents

  before_save :format, :create_remember_token

  validate :current_password?

  private

  # Control by an update if the current_password is right
  def current_password?
    if current_password && !self.authenticate(current_password)
  	 errors.add(:current_password, "does not match password")
    end
  end

  private

  # Remove spaces and capitales
  def format
    self.email.try(:strip!)
    self.email.try(:downcase!)
    self.name.try(:strip!)
  end

  def create_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
  end
end
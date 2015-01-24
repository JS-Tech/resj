class Card < ActiveRecord::Base
  include AutosaveAssociatedRecords
  include Wizard
  include CardValidation
  include CardSearch
  attr_writer :tag_names

  scope :regional, -> { joins(:card_type).where(card_types: {name: "Réseau régional"}) }
  scope :with_card_type, -> { includes(:card_type) }
  scope :active, -> { joins(:status).where(statuses: { name: "En ligne" }) }

  belongs_to :card_type
  belongs_to :user #owner of the card
  belongs_to :location
  belongs_to :status

  has_many :card_affiliations, dependent: :destroy
  has_many :affiliations, through: :card_affiliations

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings, after_remove: :update_index

  has_many :verificator_comments

  # Card's responsables (Responsable)
  has_many :card_responsables, dependent: :destroy
  has_many :responsables, through: :card_responsables

  # Card's signed up responsables (User)
  has_many :card_users, dependent: :destroy
  has_many :users, through: :card_users

  # Card belongs to local networks -> .parents
  # Local network has many cards -> .inverse_parents 
  has_many :card_parents, dependent: :destroy
  has_many :parents, through: :card_parents
  has_many :inverse_card_parents, :class_name => "CardParent", :foreign_key => "parent_id", dependent: :destroy
  has_many :inverse_parents, :through => :inverse_card_parents, :source => :card

  mount_uploader :avatar, LogoUploader
  mount_uploader :banner, BannerUploader

  after_save :assign_tags
  after_destroy :destroy_ownerships

  accepts_nested_attributes_for :responsables, :users, :allow_destroy => true, reject_if: proc { |a| a[:firstname].blank? && a[:lastname].blank? && a[:email].blank? }
  accepts_nested_attributes_for :affiliations, :allow_destroy => true, reject_if: proc { |a| a[:name].blank? }

  def to_param
    "#{id}-#{name}".parameterize
  end

  # Users requests to a card
  def unconfirmed_users
    User.joins(:card_users).where(card_users: {user_validated: true, card_validated: nil, card_id: id})
  end

  # Users affiliations
  def confirmed_users
    User.joins(:card_users).where(card_users: {user_validated: true, card_validated: true, card_id: id} ) << user
  end

  # Users request from a card and not answered
  def pending_users
    User.joins(:card_users).where(card_users: {user_validated: nil, card_validated: true, card_id: id}) 
  end

  def tag_names
    @tag_names || tags.map(&:name).join(' ')
  end

  # define the wizard's steps
  def steps
  	["general", "location", "team", "extra", "final"]
  end

  def current_step?(step)
    current_step.nil? || current_step == step || current_step == "final"
  end

  # Methods called before card's associations are saved (bound to accepts_nested_attributes_for)
  # Find a responsable or create a new one 
  def autosave_associated_records_for_responsables
    self.responsables = filter_responsables
    CardMailer.team_welcome(self).deliver if new_record?
  end

  def filter_responsables
    responsables.reject{ |r| r.is_contact == "true" || r._destroy == true}.map do |responsable|
      find_or_create_responsables
    end.compact
  end

  def find_or_create_responsables
    if user = User.users.find_by_email(responsable.email)
      CardUser.where(user_id: user.id, card_id: id).first_or_create(card_validated: true)
      next
    else
      Responsable.find_or_create_by(firstname: responsable.firstname, lastname: responsable.lastname, email: responsable.email)
    end
  end

  def autosave_associated_records_for_affiliations
    self.affiliations = find_or_create_related(Affiliation, affiliations)
  end

  def owner=(owner)
    card_user, new_user, password = find_or_create_owner(owner)
    self.update_attribute(:user, card_user)
    Ownership.add(user: card_user, element: "cards", type: "on_entry", id_element: id, right_read: true, right_update: true, right_create: true)
    Ownership.add(user: card_user, element: "cards/affiliations", type: "on_entry", id_element: id,
      right_create: true, right_delete: true, right_update: true, right_read: true)
    CardMailer.owner_created(self, new_user, password).deliver
  end

  def find_or_create_owner(owner)
    card_user = User.find_by_email(owner.email)
    new_user = if card_user.nil?
      password = SecureRandom.hex(8)
      card_user = User.create(firstname: owner.firstname, lastname: owner.lastname, email: owner.email, password: password, password_confirmation: password, user_type: UserType.find_by_name('user'))
      UserMailer.confirmation(card_user).deliver
    end
    return card_user, new_user.present?, password || nil
  end

  # used for in-place editing in card overview
  # params :
  # - attribute (String), name of attribute updated
  # - value, value of attribute updated
  def updated_attribute_value(attribute, value)
    case attribute
    when 'location_id'
      return Location.find(value).full_name
    when 'card_type_id'
      return CardType.find(value).name
    when 'parent_ids'
      return parents_list
    end
    return value
  end

  def parents_list
    return self.parents.inject(''){|i, a| "#{i}, #{a.name}"}[1..-1]
  end

  ##################
  #     Mapbox     #
  ##################

  # Used by mapbox to identify network markers
  def network?
    if self.card_type.name == "Réseau régional"
      return 1
    else
      return 0
    end
  end

  def network_members_coords
    coords = []
    inverse_parents.each do |parent|
      coords.push [latitude, longitude]
      coords.push [parent.latitude, parent.longitude]
    end 
    return coords
  end

  def map_point_icon
    ActionController::Base.helpers.asset_path("map/images/marker-icon-#{map_marker_color}.png")
  end

  def map_marker_color
    case card_type.name
    when "Groupe de jeunes"
      color = "red"
    when "Groupe de jeunes adultes"
      color = "green"
    when "Groupe d'action"
      color = "orange"
    when "Oeuvre jeunesse"
      color = "blue"
    when "Réseau régional"
      color = "violet"
    end
    return color
  end

  ##################
  #   end Mapbox   #
  ##################  

  ##################
  #     Images     #
  ##################

  # returns banner type based on width (w)
  def banner_type_url(w)
    return self.banner.s.url || banner_default('s') if(w <= 768) 
    return self.banner.m.url || banner_default('m') if(w <= 992) 
    return self.banner.l.url || banner_default('l') if(w <= 1200) 
    return self.banner.xl.url || banner_default('xl') if(w <= 1920) 
    return self.banner.full.url || banner_default('full')    
  end
  def banner_default(s)
    "card/banner/#{s}_default-banner.jpg"
  end

  def logo_type(w)
    return self.avatar.s.url || logo_default('s')  if(w <= 768)
    return self.avatar.thumb.url || logo_default('thumb')
  end

  def logo_default(s)
    "card/logo/#{s}_default-logo.jpg"
  end  

  ##################
  #   end images   #
  ##################

  private

  def assign_tags
    self.tags = tag_names.split(' ').map do |tag|
      if new_tag = Tag.find_by_name(tag)
        new_tag.update_attribute(:popularity, new_tag.popularity + 1)
        new_tag
      else
        Tag.create(name: tag)
      end
    end
  end

  def destroy_ownerships
    Ownership.joins(:element).where(elements: {name: ['cards', 'admin/cards', 'cards/affiliations']}, id_element: id).destroy_all
  end

end
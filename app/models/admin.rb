class Admin < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :first_name, :last_name, :organization, :twitter_handle, :email, :password, :password_confirmation, :remember_me, :location_id
  
  validates_presence_of :location_id
  
  after_create :send_admin_mail
  def send_admin_mail
     AdminsMailer.signup_notify_admin(self).deliver
  end

  def active_for_authentication? 
    super && approved? 
  end 
  
  def inactive_message 
    if !approved? 
      :not_approved 
    else 
      super # Use whatever other message 
    end 
  end

  def location_link
    unless self.location_id.nil?
      sql = "SELECT slug, organization_name FROM #{APP_CONFIG['fusion_table_id']} WHERE id='#{self.location_id}';"
      name = FT.execute(sql)
      if name.length > 0
        "<a href='http://locations.weconnectchicago.org/location/#{name.first[:slug]}'>#{name.first[:organization_name]}</a>".html_safe
      else
        ''
      end
    else
      ''
    end
  end
  
  def self.send_reset_password_instructions(attributes={})
    recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
    if !recoverable.approved?
      recoverable.errors[:base] << I18n.t("devise.failure.not_approved")
    elsif recoverable.persisted?
      recoverable.send_reset_password_instructions
    end
    recoverable
  end
end

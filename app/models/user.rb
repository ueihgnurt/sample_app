class User < ApplicationRecord
  has_many :microposts, dependent: :destroy
  has_many :active_relationships, class_name:   "Relationship",
                                  foreign_key:  "follower_id",
                                  dependent:    :destroy
  has_many :passive_relationships, class_name:   "Relationship",
                                  foreign_key:  "followed_id",
                                  dependent:    :destroy
  has_many :following,  through: :active_relationships,   source: :followed
  has_many :followers,  through: :passive_relationships,  source: :follower
  attr_accessor :remember_token, :activation_token, :reset_token

  scope :activated, ->{where activated: true}

  before_save   :downcase_email
  before_create :create_activation_digest

  validates     :name, presence: true, length: {maximum: 50}
  validates     :email, presence: true, length: {maximum: 255},
                format: {with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i},
                uniqueness: true
  validates     :password, presence: true, length: {minimum: 6}, allow_nil: true

  has_secure_password
  def self.digest string
    if ActiveModel::SecurePassword.min_cost
      BCrypt::Password.create(string, cost: BCrypt::Engine::MIN_COST)
    else
      BCrypt::Password.create(string, cost: BCrypt::Engine.cost)
    end
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = User.new_token
    update(remember_digest: User.digest(remember_token))
  end

  def authenticated? attribute, token
    digest = send("#{attribute}_digest")
    return false unless digest

    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update(remember_digest: nil)
  end

  def activate
    update(activated: true, activated_at: Time.zone.now)
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  def feed
    Micropost.feed id
  end

  def display_image
    image.variant(resize_to_limit: [500, 500])
  end

  def follow other_user
    following << other_user
  end

  def unfollow other_user
    following.delete(other_user)
  end

  def following? other_user
    following.include?(other_user)
  end

  private
  def downcase_email
    email.downcase!
  end

  def create_activation_digest
    self.activation_token  =  User.new_token
    self.activation_digest =  User.digest(activation_token)
  end
end

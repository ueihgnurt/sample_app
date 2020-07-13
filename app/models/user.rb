class User < ApplicationRecord
  attr_accessor :remember_token
  before_save{email.downcase!}
  validates :name, presence: true, length: {maximum: 50}
  validates :email, presence: true, length: {maximum: 255},
            format: {with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i},
            uniqueness: true
  validates :password, presence: true, length: {minimum: 6}
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

  def authenticated? remember_token
    return false if remember_digest.blank?

    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  def forget
    update(remember_digest: nil)
  end
end

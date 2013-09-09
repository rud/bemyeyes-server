require 'mongomapper_id2'

class User
  include MongoMapper::Document

  many :tokens, :foreign_key => :user_id, :class_name => "Token"
  many :devices, :foreign_key => :user_id, :class_name => "Device"
  
  key :username, String, :required => true, :unique => true
  key :password_hash, String
  key :password_salt, String
  key :email, String, :required => true, :unique => true
  key :first_name, String, :required => true
  key :last_name, String, :required => true
  
  auto_increment!
  timestamps!
  
  before_create :encrypt_password
  
  def self.authenticate_using_username(username, password)
    user = User.first(:username => { :$regex => /#{username}/i })
    if !user.nil?
      return authenticate_password(user, password)
    end
    
    return nil
  end
  
  def self.authenticate_using_email(email, password)
    user = User.first(:email => { :$regex => /#{email}/i })
    if !user.nil?
      return authenticate_password(user, password)
    end
    
    return nil
  end
  
  def password=(pwd)
    @password = pwd
  end
  
  def to_json()
    return { "id" => self.id2,
             "username" => self.username,
             "email" => self.email,
             "first_name" => self.first_name,
             "last_name" => self.last_name,
             "role" => self.role }.to_json
  end
  
  private
  def self.authenticate_password(user, password)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      return user
    end
    
    return nil
  end
  
  private
  def encrypt_password
    if @password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(@password, password_salt)
    end
  end
end
class User
  include Guacamole::Model

  attribute :username, String
  attribute :email, String
  attribute :last_checked_at, DateTime
  attribute :last_notified_at, DateTime
  attribute :updated_at, DateTime
end

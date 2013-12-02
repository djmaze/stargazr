class UsersCollection
  include Guacamole::Collection

  ensure_hash_index on: :username, unique: true
end

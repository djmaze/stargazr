class RepositoriesCollection
  include Guacamole::Collection

  ensure_hash_index on: :full_name, unique: true

  def self.find_or_initialize_by_full_name(full_name)
    by_example(full_name: full_name).first || Repository.new(full_name: full_name)
  end
end

require 'database'

class User < Database
  def self.setup_indices
    collection = self.new.collection
    unless collection.indices.detect {|index| index.on == :username }
      collection.add_index :hash, on: [:username], unique: true
    end
  end

  #def last_notified_at
    #document['last_notified_at'].presence && Time.parse(document['last_notified_at'])
  #end

  def collection
    database['users']
  end
end

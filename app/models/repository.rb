require 'database'

class Repository < Database
  attr_accessor :full_name

  def self.setup_indices
    collection = self.new('').collection
    unless collection.indices.detect {|index| index.on == :full_name }
      collection.add_index :hash, on: [:full_name], unique: true
    end
  end

  def initialize(full_name)
    @full_name = full_name
  end
  
  def update!
    logger.debug "Updating #{full_name}"
    if latest_tag = Octokit.tags(@full_name).first
      if latest_tag.name != document['latest_tag_name']
        commit = Octokit.commit(@full_name, latest_tag.commit.sha)
        document['latest_tag_date'] = Date.parse commit.commit.committer.date
      end
      document['latest_tag_name'] = latest_tag.name
    end
    document['updated_at'] = Time.now
    document.save
  end

  def release_name
    release_for_latest_tag.try :name
  end

  def release_for_latest_tag
    @release_for_latest_tag ||= Octokit.releases(full_name).detect { |release| release.tag_name == self['latest_tag_name'] }
  end

  def new_tag_since?(time)
    return false unless time.present?
    latest_tag_date.try :>=, Date.parse(time)
  end

  def fresh?
    updated_at.try :>=, midnight
  end

  def midnight
    Time.now.beginning_of_day
  end

  def latest_tag_date
    if (latest_tag_date = document['latest_tag_date']).is_a? String
      Date.parse latest_tag_date
    else
      latest_tag_date
    end
  end

  def updated_at
    document['updated_at'].presence && Time.parse(document['updated_at'])
  end

  def document
    @document ||= begin 
      query.first_example(full_name: full_name)
    rescue Ashikawa::Core::ResourceNotFound
      #Ashikawa::Core::Document.new(database, 'full_name' => full_name)
      collection.create_document full_name: full_name
    end
  end

  def collection
    database['repositories']
  end
end

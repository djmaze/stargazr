class Repository
  include Guacamole::Model

  attribute :full_name, String
  attribute :latest_tag_date, Date
  attribute :latest_tag_name, String

  def update
    if latest_tag = Octokit.tags(full_name).first
      if latest_tag.name != latest_tag_name
        commit = Octokit.commit(full_name, latest_tag.commit.sha)
        self.latest_tag_date = Date.parse commit.commit.committer.date
      end
      self.latest_tag_name = latest_tag.name
    end
  end

  def release_name
    release_for_latest_tag.try :name
  end

  def release_for_latest_tag
    @release_for_latest_tag ||= Octokit.releases(full_name).detect { |release| release.tag_name == latest_tag_name }
  end

  def new_tag_since?(time)
    return false unless time.present?
    latest_tag_date.try :>=, time
  end

  def fresh?
    updated_at.try :>=, midnight
  end

  def midnight
    Time.now.beginning_of_day
  end
end

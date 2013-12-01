require 'logger'

class Database
  def query
    Ashikawa::Core::Query.new collection
  end

  def database
    @database ||= Ashikawa::Core::Database.new do |config|
      #config.url = 'http://localhost:8529/_db/github-starred-release-notifications'
      config.url = 'http://localhost:8529'
    end
  end

  def [](attribute)
    document[attribute]
  end

  private

  def logger
    @logger ||= Logger.new(STDOUT).tap do |l|
      l.level = Logger::DEBUG
    end
  end
end

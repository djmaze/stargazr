$:.unshift '.'
require 'app'

Octokit::Client.module_eval do
  def starred_by(user, options = {})
    path = "users/#{user}/starred"
    paginate path, options
  end
end

# Set up caching
stack = Faraday::Builder.new do |builder|
  #builder.response :logger
  builder.use Faraday::HttpCache, store: :mem_cache_store, store_options: ['localhost:11211']
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack

# Login
Octokit.configure do |c|
  c.access_token = ENV['GITHUB_ACCESS_TOKEN'].presence
end

# Iterate through users
UsersCollection.all.each do |user|
  puts "User #{user.username}"
  # Grab the data
  repositories_with_new_tags = Octokit.starred_by(user.username).collect do |repository_data|
    repository = RepositoriesCollection.find_or_initialize_by_full_name repository_data.full_name
    unless repository.fresh?
      puts "Updating #{repository_data.full_name}"
      repository.update 
      RepositoriesCollection.save(repository)
    end
    repository if repository.latest_tag_date.present? && repository.new_tag_since?(user.last_checked_at)
  end.compact

  now = Time.now
  if repositories_with_new_tags.any?
    vars = OpenStruct.new(repositories: repositories_with_new_tags, user: user)
    Slim::Engine.set_default_options :pretty => true
    text = Slim::Template.new('app/views/notification_mailer/user_notification.html.slim', {}).render(vars)
    mail = Mail.new do
      from ENV['FROM_EMAIL']
      header['Reply-To'] = ENV['REPLY_TO_EMAIL'] || ENV['FROM_EMAIL']
      to user.email
      subject 'New releases in your starred repositories'

      content_type 'text/html; charset=UTF-8'
      body text
    end
    puts mail.to_s
    mail.deliver
    user.last_notified_at = now
  end
  user.last_checked_at = now
  UsersCollection.replace user
end

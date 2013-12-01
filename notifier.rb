require 'bundler'
Bundler.require(:default, :development)

$:.unshift 'app/models'
require 'user'
require 'repository'
#require 'notification_mailer'

Octokit::Client.module_eval do
  def starred_by(user, options = {})
    path = "users/#{user}/starred"
    paginate path, options
  end
end

User.setup_indices
Repository.setup_indices

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
  c.access_token = ENV['GITHUB_ACCESS_TOKEN'] if ENV['GITHUB_ACCESS_TOKEN']
end

# Iterate through users
users = User.new.collection
0.step(users.length-1, 100) do |offset|
  users.query.all(limit: 100, skip: offset).each do |user|
    puts "User #{user['username']}"
    # Grab the data
    repositories_with_new_tags = Octokit.starred_by(user['username']).collect do |repository_data|
      repository = Repository.new repository_data.full_name
      repository.update! unless repository.fresh?
      repository if repository.latest_tag_date.present? && repository.new_tag_since?(user['last_checked_at'])
    end.compact

    now = Time.now
    if repositories_with_new_tags.any?
      vars = OpenStruct.new(repositories: repositories_with_new_tags, user: user)
      Slim::Engine.set_default_options :pretty => true
      text = Slim::Template.new('app/views/notification_mailer/user_notification.html.slim', {}).render(vars)
      mail = Mail.new do
        from ENV['FROM_EMAIL']
        header['Reply-To'] = ENV['REPLY_TO_EMAIL'] || ENV['FROM_EMAIL']
        to user['email']
        subject 'New releases in your starred repositories'

        content_type 'text/html; charset=UTF-8'
        body text
      end
      puts mail.to_s
      mail.deliver
      user['last_notified_at'] = now
    end
    user['last_checked_at'] = now
    user.save
  end
end

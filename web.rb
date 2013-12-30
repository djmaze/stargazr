$:.unshift '.'
require 'sinatra'
require 'app'
require 'slim'
require 'rack/csrf'

configure do
  # CSRF protection, see http://stackoverflow.com/a/11451231/1389203
  enable :sessions
  use Rack::Csrf, :raise => true

  set :public_folder, Proc.new { File.join(root, "static") }

  register Sinatra::Auth::Github
end

set :github_options, {
  scopes:       'user:email',
  secret:       ENV['GITHUB_CLIENT_SECRET'],
  client_id:    ENV['GITHUB_CLIENT_ID'],
}

get '/' do
  @flash = session.delete(:flash)
  slim :signup
end

get '/signup_with_github' do
  authenticate!
  username, email = github_user.login, github_user.email || github_user.api.emails.first  # FIXME: Let user choose which email to use (if he has more than one associated)
  redirect_back_with_error('missing_input') and return unless username.present? && email.present?
  redirect_back_with_error('already_registered') and return if UsersCollection.by_example(username: username).any?

  @user = User.new username: username, email: email
  UsersCollection.save @user
  slim :signed_up
end

get '/cancel' do
  authenticate!

  slim :confirm_subscription_cancellation
end

post '/cancel' do
  authenticate!

  user = UsersCollection.by_example(username: github_user.login).first
  UsersCollection.delete user if user
  slim :subscription_cancelled
end

def redirect_back_with_error(message)
  session[:flash] = message
  redirect to '/'
end

helpers do
  def csrf_tag
    Rack::Csrf.csrf_tag(env)
  end
end

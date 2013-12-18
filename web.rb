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
end

def redirect_back_with_error(message)
  session[:flash] = message
  redirect to '/'
end

get '/' do
  @flash = session.delete(:flash)
  slim :signup
end

post '/signup' do
  username, email = params.values_at :username, :email
  redirect_back_with_error('missing_input') and return unless username.present? && email.present?
  redirect_back_with_error('already_registered') and return if UsersCollection.by_example(username: username).any?

  user = User.new username: params[:username], email: params[:email]
  UsersCollection.save user
  slim :signed_up
end

helpers do
  def csrf_tag
    Rack::Csrf.csrf_tag(env)
  end
end

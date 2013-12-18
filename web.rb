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

get '/' do
  @flash = params[:flash]
  slim :signup
end

post '/signup' do
  username, email = params.values_at :username, :email
  redirect to('/?flash=missing_input') unless username.present? && email.present?

  if UsersCollection.by_example(username: username).any?
    redirect to('/?flash=already_registered')
  else
    user = User.new username: params[:username], email: params[:email]
    UsersCollection.save user
    slim :signed_up
  end
end

helpers do
  def csrf_tag
    Rack::Csrf.csrf_tag(env)
  end
end

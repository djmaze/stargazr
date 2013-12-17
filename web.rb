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

  if users.query.by_example(username: username).length > 0
    redirect to('/?flash=already_registered')
  else
    users.create_document username: params[:username], email: params[:email]
    slim :signed_up
  end
end

helpers do
  def csrf_tag
    Rack::Csrf.csrf_tag(env)
  end
end

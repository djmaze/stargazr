require 'sinatra'
require 'slim'
require 'ashikawa-core'
require 'active_support/core_ext/string'
require 'pry'

$:.unshift 'app/models'
require 'user'
ENV['RACK_ENV'] ||= 'development'
Dotenv.load ".env.#{ENV['RACK_ENV']}"

Mail.delivery_method.settings = {
  address: ENV['SMTP_ADDRESS'],
  port: ENV['SMTP_PORT'] || 465,
  ssl: ENV['SMTP_USE_SSL'] == '1',
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  domain: ENV['SMTP_DOMAIN']
}

configure do
  set :public_folder, Proc.new { File.join(root, "static") }
end

User.setup_indices
users = User.new.collection

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

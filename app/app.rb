ENV["RACK_ENV"] ||= "development"

require 'sinatra/base'
require 'sinatra/flash'
require_relative 'datamapper_setup'

class Chitter < Sinatra::Base
  enable :sessions
  set :session_secret, 'super secret'
  register Sinatra::Flash
  use Rack::MethodOverride

  get '/' do
    redirect to('/users/new')
  end

  get '/peeps' do
    @peep = Peep.all
    erb :peeps
  end

  get '/peeps/new' do
    erb :'peeps/new'
  end

  post '/peeps' do
    if session[:user_id]
      peep = Peep.create(peep: params[:peep],
                         time: Time.now,
                         composer: current_user.name,
                         user_name: current_user.username)
      redirect to('/peeps')
    else
      flash.keep[:error] = 'Please log in to compose a peep!'
      redirect to '/sessions/new'
    end
  end

  get '/users/new' do
    erb :'users/new'
  end

  post '/users' do
    @user = User.create(name: params[:name],
                       username: params[:username],
                       email: params[:email],
                       password: params[:password],
                       password_confirmation: params[:password_confirmation])
    if @user.save
      session[:user_id] = @user.id
      redirect to('/peeps')
    else
      flash.now[:error] = @user.errors.full_messages.join(", ")
      erb :'users/new'
    end
  end

  get '/sessions/new' do
    erb :'sessions/new'
  end

  post '/sessions' do
    user = User.authenticate(params[:email], params[:password])
      if user
        session[:user_id] = user.id
        redirect to('/peeps')
      else
        flash.now[:error] = 'Email or password is incorrect'
        erb :'sessions/new'
      end
  end

  delete '/sessions' do
    session[:user_id] = nil
    flash.keep[:notice] = 'Bye! Come back soon.'
    redirect to '/sessions/new'
  end

  helpers do
   def current_user
     @current_user ||= User.get(session[:user_id])
   end
  end

  run! if app_file == $0
end

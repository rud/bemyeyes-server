class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin devices namespace
  namespace '/reset-password' do
    get '/' do
      erb :reset_password
    end

    post '/' do
      @success = "Password Changed!"

      erb :password_changed
    end
  end
end

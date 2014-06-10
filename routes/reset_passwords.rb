class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin devices namespace
  namespace '/reset-password' do
    get '/' do
      erb :index
    end

    post '/' do
      @error = "yes we did it"
      @success = "yes we did it"

      erb :password_changed
    end
  end
end

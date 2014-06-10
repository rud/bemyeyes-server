class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin devices namespace
  namespace '/reset-password' do
    get '/' do
      erb :index
    end
  end
end

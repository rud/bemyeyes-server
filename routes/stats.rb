class App < Sinatra::Base
  register Sinatra::Namespace
  namespace '/stats' do
    get '/community' do
    
      return { 'blind' => Blind.count, 'helpers' => Helper.count, 'no_helped' =>Request.count }.to_json
    end
  end
end

require 'language_list'
class BMELanguage < Struct.new(:name, :iso_639_1)
  end
class App < Sinatra::Base
  register Sinatra::Namespace
  namespace '/languages' do
    get '/common' do
      LanguageList::COMMON_LANGUAGES.reject{|language|!( language.living?)}.map{|lan| BMELanguage.new lan.name, lan.iso_639_1}.to_json
    end
  end
end
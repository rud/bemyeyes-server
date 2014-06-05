require 'yaml'
require 'mongo_mapper'

class IntegrationSpecHelper
  def self.InitializeMongo
    config = YAML.load_file('config/config.yml')
    MongoMapper.connection = Mongo::Connection.new(config['database']['host'])
    MongoMapper.database = config['database']['name']
  end
end

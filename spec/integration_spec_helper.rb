require 'yaml'

class IntegrationSpecHelper
	def self.InitializeMongo
	  config = YAML.load_file('config/config.yml')
	  MongoMapper.connection = Mongo::Connection.new(config['database']['host'])
	  MongoMapper.database = config['database']['name']
	  if db_config.has_key? 'username'
 +         MongoMapper.connection[db_config['name']].authenticate(db_config['username'], db_config['password'])
 +        else
 +          MongoMapper.connection[db_config['name']]
 +        end
	end
end

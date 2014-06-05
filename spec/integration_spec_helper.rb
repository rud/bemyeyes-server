require 'yaml'

class IntegrationSpecHelper
	def self.InitializeMongo
	  config = YAML.load_file('config/config.yml')
	  MongoMapper.connection = Mongo::Connection.new(config['database']['host'])
	  MongoMapper.database = config['database']['name']
	  if config['database'].has_key? 'username'
 +         MongoMapper.connection[config['database']['name']].authenticate(config['database']['username'], config['database']['password'])
 +        else
 +          MongoMapper.connection[config['database']['name']]
 +        end
	end
end

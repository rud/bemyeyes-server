require 'yaml'

class IntegrationSpecHelper
	def self.InitializeMongo
		config = YAML.load_file('config/config.yml')
	    MongoMapper.connection = Mongo::Connection.new(config['database']['host'])
	    MongoMapper.database = config['database']['name']
	    MongoMapper.connection['bemyeyes'].authenticate(config['database']['username'], config['database']['password'])
	end
end
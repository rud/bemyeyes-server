BeMyEyes Server
====

[![Code Climate](https://codeclimate.com/github/bemyeyes/bemyeyes-server.png)](https://codeclimate.com/github/bemyeyes/bemyeyes-server)

##Getting started
gem install bundler  
bundle install  
  
install mongodb  

start mongo shell  
    db.addUser( { user: "bemyeyes",
              pwd: "myPassword",
              roles: [ "readWrite", "dbAdmin" ]
            } )

##Start the server locally
Copy config.yml to the config folder    
Use the config.temp.yml as a template    
ruby -S rackup -w config.ru

All interactions with the server demands HTTP Basic AUTH - the username password can be found in the config file under the "authentication" section.

##	Setup server 
Install rbenv system wide
https://gist.github.com/jnx/1256593

		# Update, upgrade and install development tools:
		apt-get update
		apt-get -y upgrade
		apt-get -y install build-essential
		apt-get -y install git-core
		apt-get install libssl-dev

		# Install rbenv
		git clone git://github.com/sstephenson/rbenv.git /usr/local/rbenv
		 
		# Add rbenv to the path:
		echo '# rbenv setup' > /etc/profile.d/rbenv.sh
		echo 'export RBENV_ROOT=/usr/local/rbenv' >> /etc/profile.d/rbenv.sh
		echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> /etc/profile.d/rbenv.sh
		echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
		 
		chmod +x /etc/profile.d/rbenv.sh
		source /etc/profile.d/rbenv.sh
		 
		# Install ruby-build:
		pushd /tmp
		  git clone git://github.com/sstephenson/ruby-build.git
		  cd ruby-build
		  ./install.sh
		popd
		 
		# Install Ruby 2.0.0p353:
		rbenv install 2.0.0p353
		rbenv global 2.0.0p353
		 
		# Rehash:
		rbenv rehash

Install Passenger
http://www.modrails.com/documentation/Users%20guide%20Apache.html#install_on_debian_ubuntu
gem install passenger


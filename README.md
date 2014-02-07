BeMyEyes Server
============
##Getting started
gem install bundler
bundle install

install mongodb

start mongo shell
db.addUser( { user: "bemyeyes",
              pwd: "GuideBlind2012",
              roles: [ "readWrite", "dbAdmin" ]
            } )

##Start the server
ruby app.rb
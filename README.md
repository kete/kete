# Kete 2.0

[![Build Status](https://travis-ci.org/kete/kete.svg?branch=kete2)](https://travis-ci.org/kete/kete)
[![security](https://hakiri.io/github/kete/kete/master.svg)](https://hakiri.io/github/kete/kete/master)
[![Code Climate](https://codeclimate.com/github/kete/kete/badges/gpa.svg)](https://codeclimate.com/github/kete/kete)
[![Test Coverage](https://codeclimate.com/github/kete/kete/badges/coverage.svg)](https://codeclimate.com/github/kete/kete/coverage)
[![Issue Count](https://codeclimate.com/github/kete/kete/badges/issue_count.svg)](https://codeclimate.com/github/kete/kete)

Kete is a knowledge basket of images, audio, video and documents which are collected and catalogued by the community.

## Deploy to your own heroku

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)


## Important note for Kete 1.x users

There is no upgrade path from the old kete1 to kete2 yet. Patches are very welcome.

## Development Milestones

### Read Only Functionality
- there is a known issue where some links are broken on pages within Kete. These are pending investigation

### User Accounts and Create/Edit Functionality on Items
next milestone

### Administrator features are complete
final milestone of this development phase


## Contributing

The following is a brief summary how to setup Kete for development

```sh
git clone https://github.com/kete/kete
cd kete
git checkout kete2

cp ./config/database.example.yml ./config/database.yml

npm install                     # install grunt which is used to lint JS
bundle                          # install gems
bundle exec rspec               # run specs
bundle exec rake db:create      # create databases
bundle exec rake db:setup       # includes db:schema:load and db:seed
bundle exec rails server

# Before committing any changes:
bundle exec rubocop             # lint ruby
./node_modules/.bin/grunt       # lint JS
```

# Credits

Kete is Copyright (C) 2006-2012 Horowhenua Library Trust and Others under the GPL version 2 license.  See license.txt for details.

# Kete 2.0 work in progress

[![Build Status](https://travis-ci.org/kete/kete.svg?branch=kete2)](https://travis-ci.org/kete/kete)

This branch is a partially complete modernisation of the Kete codebase

* upgrade to Rails 3
* move dependencies to gems that are currently being maintained.

This work is not yet complete so this branch is not ready for production use.
You can view existing content in the Kete but creating or editing content is not
working yet.

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

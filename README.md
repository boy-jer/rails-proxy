rails-proxy
=============

rails-proxy is a rails proxy for railsbp.com, it should be executed on ruby 1.9.2

Usage
-----

    bundle install

    cp config/railsbp.yml.example config/railsbp.yml

    rackup

Deployment
----------

**directly clone source codes**

    git clone git://github.com/railsbp/rails-proxy.git

you should create config/railsbp.yml and config/rails_best_practices.yml according to the examples.

**with capistrano**

    capify .

here is an example

    https://gist.github.com/1746308

setup on remote server

    cap deploy:setup

you should create shared/config/railsbp.yml and shared/config/rails_best_practices.yml on remote server according to the examples.

finally

    cap deploy

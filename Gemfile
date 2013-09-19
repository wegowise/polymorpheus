source 'https://rubygems.org'
gemspec

# The AR environment variable lets you test against different
# versions of Rails. For example:
#
#  AR=3.2.13 rm Gemfile.lock && bundle install && bundle exec rspec
#  AR=4.0.0  rm Gemfile.lock && bundle install && bundle exec rspec
#
if ENV['AR']
  gem 'activerecord', ENV['AR']
end

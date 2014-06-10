# -*- encoding: utf-8 -*-
require 'rubygems' unless defined? Gem
require File.dirname(__FILE__) + "/lib/polymorpheus/version"

Gem::Specification.new do |s|
  s.name        = "polymorpheus"
  s.version     = Polymorpheus::VERSION

  s.authors     = ["Barun Singh"]
  s.email       = "bsingh@wegowise.com"
  s.homepage    = "http://github.com/wegowise/polymorpheus"
  s.summary     = "Provides a database-friendly method for polymorphic relationships"
  s.description = "Provides a database-friendly method for polymorphic relationships"

  s.required_rubygems_version = ">= 1.3.6"
  s.files = Dir.glob(%w[{lib,spec}/**/*.rb [A-Z]*.{txt,rdoc,md} *.gemspec]) + %w{Rakefile}
  s.extra_rdoc_files = ["README.md", "LICENSE.txt"]
  s.license = 'MIT'

  s.add_dependency('foreigner')
  s.add_dependency('activerecord', '>= 3.2', '< 5.0')
  s.add_development_dependency('rspec-rails', '~> 2.14.0')
  s.add_development_dependency('mysql2', '~> 0.3')
end

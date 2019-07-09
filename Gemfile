# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

group :development do
  gem 'rubocop', '~> 0.71'
end

group :deployment do
  gem 'package_cloud'
  gem 'rake'
end

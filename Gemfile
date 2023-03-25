# frozen_string_literal: true

source 'https://rubygems.org'

ruby File.read('.ruby-version').chomp

gemspec

group :test do
  gem 'rspec', '~> 3.12'
end

group :lint do
  gem 'rubocop', '~> 1.31.1'
  gem 'rubocop-rspec', '~> 2.11.1'
end

gem 'pry', '~> 0.13.1'
gem 'pry-byebug', '~> 3.9'

gem 'dotenv', '~> 2.8'

gem 'slop', '~> 4.10'

# frozen_string_literal: true

source 'https://rubygems.org'

ruby File.read('.ruby-version').chomp

gemspec

group :test do
  gem 'rspec', '~> 3.12'
end

group :lint do
  gem 'rubocop'
  gem 'rubocop-rspec'
end

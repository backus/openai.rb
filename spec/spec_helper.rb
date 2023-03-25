# frozen_string_literal: true

require 'openai'
require 'pry'
require 'pry-byebug'

module OpenAISpec
  ROOT = Pathname.new(__dir__).parent
  SPEC_ROOT = ROOT.join('spec')
end

RSpec.configure do |config|
  # Enable focused tests and run all tests if nothing is focused
  config.filter_run_when_matching(:focus)

  # Forbid RSpec from monkey patching any of our objects
  config.disable_monkey_patching!

  # We should address configuration warnings when we upgrade
  config.raise_errors_for_deprecations!

  # RSpec gives helpful warnings when you are doing something wrong.
  # We should take their advice!
  config.raise_on_warning = true

  config.mock_with(:rspec) do |mocks|
    # Verifies stubbed methods on real objects.
    # @see https://relishapp.com/rspec/rspec-mocks/docs/verifying-doubles/partial-doubles
    mocks.verify_partial_doubles = true
  end

  config.expect_with(:rspec) do |expectations|
    # Set a higher max length for RSpec's test failure output, so it doesn't as aggressively
    # truncate test failure explanations, obscuring the test failure reason in the process
    # @note The default output length is 200 characters
    # @see https://www.rubydoc.info/github/rspec/rspec-expectations/RSpec%2FExpectations%2FConfiguration:max_formatted_output_length=
    expectations.max_formatted_output_length = 600
  end

  # Write rspec results to a temporary file so that we can use `rspec --only-failures`
  config.example_status_persistence_file_path =
    OpenAISpec::ROOT.join('tmp', 'rspec.txt').to_s

  # Always aggregate failures when there are multiple expectations. This makes debugging tests with
  # multiple expectations much easier because we can see the failures of each expectation together.
  config.define_derived_metadata do |metadata|
    metadata[:aggregate_failures] = true
  end

  # Define metadata for all tests which live under spec/unit
  config.define_derived_metadata(file_path: %r{\bspec/unit/}) do |metadata|
    # Set the type of these tests as 'unit'
    metadata[:type] = :unit
  end
end

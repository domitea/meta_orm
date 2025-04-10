# frozen_string_literal: true

require "zeitwerk"
module MetaOrm
  class Error < StandardError; end
  # Your code goes here...

  loader = Zeitwerk::Loader.for_gem
  loader.setup
end

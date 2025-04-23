# frozen_string_literal: true

require "zeitwerk"
module MetaOrm
  class Error < StandardError; end

  loader = Zeitwerk::Loader.for_gem
  loader.setup
end

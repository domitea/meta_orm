# frozen_string_literal: true

module MetaOrm
  class BlueprintRegistry
    @blueprints = []

    class << self
      def register(bp)
        @blueprints << bp
      end

      def blueprints
        @blueprints
      end
    end
  end
end
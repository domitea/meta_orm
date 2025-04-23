# frozen_string_literal: true

module MetaOrm
  class Base < SequelModel

    def self.inherited(subclass)
      super
      MetaORM::ModelRegistry.register(subclass)

      subclass.set_dataset(subclass.name.split('::').last.snake_case.pluralize.to_sym) rescue nil

      blueprint_name = "#{subclass.name}Blueprint"
      if Object.const_defined?(blueprint_name)
        blueprint = Object.const_get(blueprint_name)
        blueprint.attributes_meta.each do |name, opts|
          subclass.attribute(name, **opts)
        end
      end
    end

    class << self
      attr_reader :attributes_meta, :transforms, :warnings, :alerts, :enums, :indices, :before_save_callbacks, :after_save_callbacks

      def transform(name, &block)
        @transforms ||= {}
        @transforms[name.to_sym] = block
      end

      def alert_if(name, op, threshold)
        @alerts ||= []
        @alerts << { attr: name.to_sym, op: op, threshold: threshold }
      end

      def warn_if(name, op, threshold)
        @warnings ||= []
        @warnings << { attr: name.to_sym, op: op, threshold: threshold }
      end

      def before_save(&block)
        @before_save_callbacks ||= []
        @before_save_callbacks << block
      end

      def after_save(&block)
        @after_save_callbacks ||= []
        @after_save_callbacks << block
      end

      def metadata_for(attr)
        @attributes_meta[attr.to_sym]
      end

      def describe_model
        puts "#{name}:"
        @attributes_meta.each do |k, meta|
          desc = "- #{k} [#{meta[:type]}"
          desc += ", #{meta[:unit]}" if meta[:unit]
          desc += ", range: #{meta[:range]}" if meta[:range]
          desc += ", enum: #{meta[:enum]}" if meta[:enum]
          desc += ", index" if meta[:index]
          desc += "]"
          puts desc
        end
      end

      def example_data!
        inst = new
        @attributes_meta.each do |k, meta|
          inst[k] = meta[:test_value] || meta[:default]
        end
        inst
      end
    end

    # method that generates example data
    # if we have defined range, use rand on that range
    # if we have default, use default
    # if we have nothing... it's nil
    def example_data
      example_data = {}
      self.class.attributes_meta.each do |k, meta|
        example_data[k] = if meta.key?(:range)
                            Random.rand(meta[:range])
                          elsif meta.key?(:default)
                            meta[:default]
                          end
      end
    end

    def transform_all!
      self.class.transforms&.each_value do |block|
        instance_exec(&block)
      end
    end

    def run_callbacks(list)
      (self.class.send(list) || []).each do |cb|
        instance_exec(&cb)
      end
    end

    def before_save
      transform_all!
      run_callbacks(:before_save_callbacks)
      super
    end

    def after_save
      run_callbacks(:after_save_callbacks)
      emit_observe_events
      super
    end

    def emit_observe_events
      return unless respond_to?(:changed_columns)

      changed_columns.each do |col|
        next unless self.class.attributes_meta.key?(col)

        Takagi::Reactor.emit(self.class, col, self[col]) if defined?(Takagi::Reactor)
      end
    end

    def validate
      super
      (self.class.attributes_meta || {}).each do |name, meta|
        val = send(name)

        if meta[:range] && !val.nil?
          errors.add(name, "must be within #{meta[:range]}") unless meta[:range].include?(val)
        end

        next unless meta[:enum] && !val.nil?

        errors.add(name, "must be one of #{meta[:enum].join(", ")}") unless meta[:enum].include?(val)
      end
    end
  end
end
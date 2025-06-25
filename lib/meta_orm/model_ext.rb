# frozen_string_literal: true
module MetaOrm
  module ModelExt
    def self.apply(model)
      model.instance_eval do
        MetaORM::ModelRegistry.register(subclass)

        blueprint_name = "#{subclass.name}Blueprint"
        if Object.const_defined?(blueprint_name)
          @blueprint = Object.const_get(blueprint_name)
        end
      end
    end

    module ClassMethods
      attr_reader :transforms, :warnings, :alerts, :before_save_callbacks, :after_save_callbacks, :attributes_meta

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
        return "Blueprint not found" unless @blueprint

        puts "#{name}:"
        attributes_meta.each do |k, meta|
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
        return "Blueprint not found" unless @blueprint

        @blueprint.attributes_meta.transform_values do |meta|
          if meta[:range]
            rand(meta[:range])
          elsif meta[:default]
            meta[:default]
          end
        end
      end

      def blueprint(name)
        @blueprint = Object.const_get(blueprint_name)
      end

      def attributes_meta
        return @blueprint.attributes_meta if @blueprint
        nil
      end
    end

    module InstanceMethods
      def transform_all!
        run_callbacks(:transform_callbacks)
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
          if meta[:range] && val && !meta[:range].include?(val)
            errors.add(name, "must be within #{meta[:range]}")
          end

          if meta[:enum] && val && !meta[:enum].include?(val)
            errors.add(name, "must be one of #{meta[:enum].join(', ')}")
          end
        end
      end
    end
  end
end

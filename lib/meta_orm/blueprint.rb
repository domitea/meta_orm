# frozen_string_literal: true

module MetaOrm
  class Blueprint

    def self.inherited(subclass)
      super
      model_name = subclass.name.to_s
      table_name = subclass.name.to_s.to_sym
      primary_key = :id

      subclass.instance_variable_set(:@table_name, table_name)
      subclass.instance_variable_set(:@model_name, model_name)
      subclass.instance_variable_set(:@primary_key, primary_key)
      MetaOrm::BlueprintRegistry.register(subclass)
    end

    class << self
      attr_reader :attributes_meta, :indices, :table_name, :model_name, :primary_key

      def attribute(name, type:, unit: nil, range: nil, default: nil, display_name: nil, semantic: nil, enum: nil, index: false, **_opts)
        @attributes_meta ||= {}
        @indices ||= []

        @attributes_meta[name.to_sym] = {
          type: type,
          unit: unit,
          range: range,
          default: default,
          display_name: display_name,
          semantic: semantic,
          enum: enum,
          index: index
        }.compact

        @indices << name.to_sym if index
      end

      def build_model_methods
        mod = Module.new
        @attributes_meta.each do |name, meta|
          mod.define_method(name) { self[name] }
          mod.define_method("#{name}=") { |val| self[name] = val }

          if meta[:enum]
            mod.define_method("#{name}_valid?") { meta[:enum].include?(self[name]) }
          end
        end
        mod
      end
    end
  end
end
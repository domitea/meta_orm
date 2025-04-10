module MetaORM
  module ModelRegistry
    @models = []

    def self.register(model_class)
      @models << model_class
    end

    def self.models
      @models
    end

    def self.describe_all
      @models.each(&:describe_model)
    end
  end
end
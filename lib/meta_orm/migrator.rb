# frozen_string_literal: true

module MetaORM
  class Migrator
    def self.migrate
      migrations = Dir["db/migrations/*.rb"].sort
      migrations.each do |migration|
        require_relative "../#{migration}"
        version = migration.split('/').last.split('.').first
        unless schema_migrated?(version)
          puts "Running migration: #{version}"
          Object.const_get("Migration#{version}").new.change
          mark_as_migrated(version)
        end
      end
    end

    def self.schema_migrated?(version)
      DB[:schema_migrations].where(version: version).count > 0
    end

    def self.mark_as_migrated(version)
      DB[:schema_migrations].insert(version: version, created_at: Time.now)
    end

    def self.auto_migrate
      models = MetaORM::ModelRegistry.models
      models.each do |model_class|
        changes = SchemaComparer.compare(model_class)
        if changes.any?
          puts "Applying changes for #{model_class.name}:"
          changes.each { |change| puts "  - #{change}" }
          DB.alter_table(model_class.table_name) do
            changes.each { |sql| execute(sql) }
          end
        else
          puts "#{model_class.name} - No changes detected."
        end
      end
    end
  end
end

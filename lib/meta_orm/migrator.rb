# frozen_string_literal: true

require 'sequel/extensions/migration'

module MetaOrm
  class Migrator
    def self.bootstrap!
      Dir.mkdir("db") unless Dir.exist?("db")
      Dir.mkdir("db/migrations") unless Dir.exist?("db/migrations")

      puts "Bootstrapping MetaORM schema..."
      auto_migrate!
    end

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

    def self.auto_migrate!
      blueprints = MetaOrm::BlueprintRegistry.blueprints
      migration_files = []

      blueprints.each do |blueprint_class|
        file = MetaOrm::SchemaComparer.generate_migration(blueprint_class)
        migration_files << file if file
      end

      if migration_files.any?
        puts "\nRunning migrations:"
        Sequel::Migrator.run(DB, "db/migrations")
      else
        puts "\nNo schema changes detected, skipping migration run."
      end
    end
  end
end

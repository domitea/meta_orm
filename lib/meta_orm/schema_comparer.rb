# frozen_string_literal: true

module MetaOrm
  class SchemaComparer
    def self.generate_migration(blueprint_class)
      model_attributes = blueprint_class.attributes_meta
      table_name = blueprint_class.table_name

      table_exists = DB.table_exists?(table_name)
      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      migration_file = "db/migrations/#{timestamp}_create_#{table_name}.rb"
      changes = []

      if table_exists
        puts "Updating table #{table_name}..."

        table_columns = DB[table_name].columns
        table_info    = DB.schema(table_name)

        missing_columns = model_attributes.keys - table_columns
        missing_columns.each do |column|
          type = model_attributes[column][:type]
          changes << "add_column :#{column}, :#{type}#{column_options(model_attributes[column])}"
        end

        extra_columns = table_columns - model_attributes.keys
        extra_columns.each do |column|
          changes << "remove_column :#{column}"
        end

        table_info.each do |column, info|
          column_name = column.to_sym
          if model_attributes[column_name]
            column_type = info[0]
            if column_type.to_s != model_attributes[column_name][:type].to_s
              changes << "change_column :#{column}, :#{model_attributes[column_name][:type]}"
            end
          end
        end
      else
        puts "Table #{table_name} does not exist. Generating full create_table migration..."
        changes << "create_table :#{table_name} do"
        model_attributes.each do |column, meta|
          changes << "  column :#{column}, :#{meta[:type]}#{column_options(meta)}"
        end
        changes << "end"
      end

      if changes.any?
        File.open(migration_file, 'w') do |f|
          f.puts "Sequel.migration do"
          f.puts "  change do"
          changes.each { |line| f.puts "    #{line}" }
          f.puts "  end"
          f.puts "end"
        end
        puts "Migration file created: #{migration_file}"
        migration_file
      else
        puts "No changes detected for model: #{blueprint_class.name}"
        nil
      end
    end

    def self.column_options(meta)
      options = []
      options << "NOT NULL" if meta[:required]
      options << "DEFAULT #{meta[:default]}" if meta[:default]
      options << "CHECK (#{meta[:range]})" if meta[:range]
      options.join(" ")
    end
  end
end

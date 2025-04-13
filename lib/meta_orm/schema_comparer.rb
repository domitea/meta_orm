# frozen_string_literal: true

module MetaORM
  class SchemaComparer
    def self.generate_migration(model_class)
      model_attributes = model_class.attributes_meta
      table_columns = DB[model_class.table_name].columns
      table_info = DB.schema(model_class.table_name)

      changes = []
      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      migration_file = "db/migrations/#{timestamp}_create_#{model_class.table_name}.rb"

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

      if changes.any?
        File.open(migration_file, 'w') do |f|
          f.puts "class Migration#{timestamp}Create#{model_class.table_name.capitalize}"
          f.puts "  def change"
          changes.each do |change|
            f.puts "    #{change}"
          end
          f.puts "  end"
          f.puts "end"
        end
        puts "Migration file created: #{migration_file}"
      else
        puts "No changes detected for model: #{model_class.name}"
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

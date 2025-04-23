# frozen_string_literal: true

require 'sequel'

module MetaOrm
  SequelModel = Class.new(Sequel::Model)
  SequelModel.def_Model(self)
  SequelModel.plugin :timestamps, update_on_create: true
end
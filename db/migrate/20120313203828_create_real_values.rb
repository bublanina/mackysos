# -*- encoding : utf-8 -*-
class CreateRealValues < ActiveRecord::Migration
  def change
    create_table :real_values do |t|
      t.datetime :cas
      t.decimal :vykon, :precision => 10, :scale => 5
      t.decimal :teplota, :precision => 10, :scale => 5
      t.decimal :osvit, :precision => 11, :scale => 5

      t.timestamps
    end
  end
end

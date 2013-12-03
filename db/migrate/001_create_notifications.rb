class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :action
      t.integer :entity_id
      t.integer :param_id
      t.string :param_model
      t.timestamps
    end
  end
end
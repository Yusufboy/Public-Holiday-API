class CreateLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :logs do |t|
      t.string :request
      t.string :response
      t.string :from_api

      t.timestamps
    end
  end
end

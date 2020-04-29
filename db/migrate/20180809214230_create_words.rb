class CreateWords < ActiveRecord::Migration[5.2]
  def change
    create_table :words do |t|
      t.string :spelling, null: false, limit: 40
    end
  end
end

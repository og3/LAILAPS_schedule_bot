class CreateLessons < ActiveRecord::Migration[5.0]
  def change
    create_table :lessons do |t|
      t.string  :name
      t.string  :trainer
      t.integer :day_of_the_week
      t.integer :number_of_lessons
      t.time :start_on
      t.time :end_on
      t.integer :start_on_int
      t.integer :end_on_int
      t.timestamps
    end
  end
end

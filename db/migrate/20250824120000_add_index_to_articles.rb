class AddIndexToArticles < ActiveRecord::Migration[7.2]
  def change
    add_index :articles, :id
    add_index :articles, :created_at
    add_index :articles, [:created_at, :id]
  end
end
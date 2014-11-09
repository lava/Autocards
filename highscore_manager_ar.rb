require 'active_record'

#ActiveRecord classes for the highscore manager

class Score < ActiveRecord::Base
end


class SetupHighscoreDatabase < ActiveRecord::Migration
	def self.up
		create_table :scores do |t|
			t.string :name
			t.integer :game_length
			t.string :filename
			t.integer :correct
			t.integer :skipped
			t.integer :duration
		end
	end

	def self.down
		drop_table :scores
	end
end


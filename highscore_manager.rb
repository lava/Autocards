require 'rubygems'
require 'yaml'
require 'active_record'

require './highscore_manager_ar'

#TODO add some way to actually get the stored highscores
class HighscoreManager
	HIGHSCORE_FILE = './highscores.db'

	def initialize()
		#create file if it doesnt exist
		path = HighscoreManager::HIGHSCORE_FILE
		unless File.exist? path
			fresh_db = true
		end

		establish_db_connection(path)

		SetupHighscoreDatabase.up if fresh_db
	end

	def establish_db_connection(path)
		ActiveRecord::Base.establish_connection(
			:adapter => "sqlite3",
			:database => path
		)

		Score.establish_connection(
			:adapter => "sqlite3",
			:database => path
		)
	end

	def add_score(name, filepath, game_length, correct, skipped, duration)
		raise "Invalid pdf name" unless filepath.is_a? String
		filename = filepath.split("/").last
		score = Score.create do |s|
			s.name = name 
			s.filename = filename 
			s.game_length = game_length
		       	s.correct = correct
		       	s.skipped = skipped
			s.duration = duration
		end
		score.save
	end
end

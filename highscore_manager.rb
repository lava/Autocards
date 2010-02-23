require 'yaml'
require 'score'


#TODO move to sqlite, maybe even activerecord
class HighscoreManager
	HIGHSCORE_FILE = './hiscore.yaml'

	def initialize(filename = HighscoreManager::HIGHSCORE_FILE)
		#create file if it doesnt exist
		@filename = filename
		unless File.exist? filename
			File.open(filename, "w") {|io| YAML.dump({}, io) }
		end

		@hiscores = YAML.load_file(filename)
		unless @hiscores.is_a? Hash
			raise "Corrupted highscore file."
		end
	end

	def add_score(username, pdfname, length, correct, skipped, time)
		raise "Invalid pdf name" unless pdfname.is_a? String
		name = pdfname.split("/").last
		score = Score.new(username, name, length, correct, skipped, time)
		@hiscores[name] ||= []
		@hiscores[name] << score

		#p @hiscores.inspect

		# if there are destructors in ruby, one has to do this once
		File.open(@filename, "w") {|io| YAML.dump(@hiscores, io) }
	end
end

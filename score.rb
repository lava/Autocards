class Score
	attr_accessor :name, :filename, :length, :correct, :skipped, :time

	def initialize(*args)
		@name, @filename, @numquestions, @correct, @skipped, @time, rest = *args
	end
end

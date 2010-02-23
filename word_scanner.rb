require 'poppler'

require 'word'

class WordScanner
	def initialize(options = {})
		#no options yet
	end

	def scan(file)
		doc = Poppler::Document.new(file)
		pages = doc.n_pages
		@words = []
		0.upto(doc.n_pages-1).each do |i|
			page = doc.get_page(i)
			rect = Poppler::Rectangle.new(0,0,-1,-1) 
			#get_text seems to return the whole text on the 
			#site regardless of what we pass as argument, but
			#i'm not sure if this is a bug or if i dont understand
			#the calling conventions
			text = page.get_text(rect).gsub(/[.:,;„“?!\[\]()\f\n\/0-9%]/, " ")
			@words += text.split(" ").select {|w| w.size > 5 || (w != w.downcase && w.size > 3)}.uniq.map {|w| Word.new(i, w)}
		end
		puts "Found #{@words.size} words total."
		return self
	end

	def get_words
		@words
	end
end

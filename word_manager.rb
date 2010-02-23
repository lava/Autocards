require 'rubygems'
require 'sqlite3'
require 'activerecord'

require 'word_manager_ar'
require 'word_scanner'

class WordManager
	DB_PATH = './banwords.db'

	def initialize(pdfpath)
		raw_words = WordScanner.new.scan(pdfpath).get_words
		fresh_db = true	unless File.exist? WordManager::DB_PATH
		@filename = pdfpath.split("/").last
		ActiveRecord::Base.establish_connection(
			:adapter => "sqlite3",
			:database => WordManager::DB_PATH
		)

		SetupBannedWordDatabase.up if fresh_db

		doc = PDFDocument.find(:first, :conditions => {:filename => @filename })
		if doc.nil?
			#create new entry for this file if it doesnt exist
			doc = PDFDocument.create(:filename => @filename)
			doc.save
		end
		@document_id = doc.id

		p @document_id
		banned_words = BannedWord.find(:all, :conditions => { :document_id => @document_id }).map {|bw| Word.new(bw.page, bw.text)}
		p banned_words
		@words = raw_words - banned_words
	end

	def random_word
		@words.choice
	end

	def ban(text, page)
		BannedWord.create(:text => text, :page => page, :document_id => @document_id).save
		#make sure the banned word doesnt appear again this game
		bw = Word.new(page, text)
		@words.reject {|w| w.eql? bw}
	end
end

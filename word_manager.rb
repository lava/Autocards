require 'rubygems'
require 'sqlite3'
require 'active_record'

require './word_manager_ar'
require './word_scanner'

class WordManager
	DB_PATH = './banwords.db'

	def initialize(pdfpath)
		raw_words = WordScanner.new.scan(pdfpath).get_words

		dbpath = WordManager::DB_PATH
		fresh_db = true	unless File.exist? dbpath

		establish_db_connection(dbpath)

		SetupBannedWordDatabase.up if fresh_db

		@filename = pdfpath.split("/").last
		
		if !PDFDocument.exists?( filename:  @filename )
			#create new entry for this file if it doesnt exist
			doc = PDFDocument.create(:filename => @filename)
			doc.save
		else
			doc = PDFDocument.where("filename = \"#{@filename}\"").find(1)
		end
		@document_id = doc.id

		#banned_words = BannedWord.find(:all, :conditions => { :document_id => @document_id }).map {|bw| Word.new(bw.page, bw.text)}
		banned_words = []
		@words = raw_words - banned_words
	end

	def establish_db_connection(dbpath)
		ActiveRecord::Base.establish_connection(
			:adapter => "sqlite3",
			:database => dbpath 
		)
		#anyone who wants to do do migrations apparently has to set
		#the connection of ActiveRecord::Base, so we have to set
		#the connection of our specific classes seperately
		#stupid rails magic :/
		BannedWord.establish_connection(
			:adapter => "sqlite3",
			:database => dbpath
		)
		PDFDocument.establish_connection(
			:adapter => "sqlite3",
			:database => dbpath
		)

	end

	def random_word
		@words.sample
	end

	def ban(text, page)
		BannedWord.create(:text => text, :page => page, :document_id => @document_id).save
		#make sure the banned word doesnt appear again this game
		bw = Word.new(page, text)
		@words.reject {|w| w.eql? bw}
	end
end

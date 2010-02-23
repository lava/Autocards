require 'activerecord'

#ActiveRecord classes for the WordManager

class PDFDocument < ActiveRecord::Base
	set_table_name 'documents'
end

class BannedWord < ActiveRecord::Base
end

class SetupBannedWordDatabase < ActiveRecord::Migration
	def self.up
		create_table :documents do |t|
			t.string :filename
		end

		add_index :documents, :filename, :unique

		create_table :banned_words do |t|
			t.references :document
			t.integer :page
			t.string :text
		end
	end

	def self.down
		drop_table :documents
		drop_table :banned_words
	end
end

require 'gtk2'
	
require 'poppler'

require './word_manager'
require './highscore_manager'

class AutoQuiz
	DEFAULT_GAME_LENGTH = 15

	def initialize(filename)
		srand(Time.now.to_i)
		#initialize various fields
		@filename = filename
		@doc = Poppler::Document.new(filename)
		@npages = @doc.n_pages
		@current_page = @doc.get_page(0)
		@hsize, @vsize = @current_page.size.map {|x| x.ceil}
		@word_manager = WordManager.new(filename)
		@highscore_manager = HighscoreManager.new
		@current_word = ""
		@rects = []
		@game_in_progress = false
		@start_time = nil
		@game_length = AutoQuiz::DEFAULT_GAME_LENGTH
		@correct = 0
		@incorrect = 0
		@skipped = 0
		@username = nil

		# initialize GUI
		@top_window = Gtk::Window.new
		@top_window.set_title( "Do you *really* know your stuff?" )
		vbox = Gtk::VBox.new(false)
		@drawing_area = Gtk::DrawingArea.new
		@drawing_area.set_size_request(@hsize, @vsize)
		@text_field = Gtk::Entry.new
		@text_field.set_max_length(@hsize)
		@text_field.set_text("Type '#start [n]' to begin game. Use #ban to permanently ban a word, #name [name] to change your name and #quit to quit.")
		@text_field.select_region(0,-1)
		vbox.add(@drawing_area)
		vbox.add(@text_field)
		@top_window.add(vbox)

		#add necessary callback functions
		@text_field.signal_connect('activate') {|w| enter_callback(w)}
		@drawing_area.signal_connect('expose_event') {|w, e| draw_callback(w, e)}
		@top_window.signal_connect('delete_event') { Gtk.main_quit }
		@top_window.show_all
	end

	def next_word
		word = @word_manager.random_word
		#p word
		@current_word = word.text
		@current_page = @doc.get_page(word.page)
		@rects = @current_page.find_text(word.text)
		@top_window.queue_draw
	end

	def draw_callback(w,e)
		window = @drawing_area.window
		context = window.create_cairo_context
		@current_page.render(context)

		gc = Gdk::GC.new(window)
		@rects.each do |r|
			left, right = [r.x1, r.x2].minmax
			# pdf has the origin in the lower left corner,
			# gtk in the upper left
			lower, upper = [r.y1, r.y2].minmax.map {|y| @vsize - y}
			window.draw_rectangle(gc, true, left, upper, right - left, lower - upper)
		end
	end

	def enter_callback(entry)
		text = entry.text.split(" ")
		entry.delete_text(0,-1)
		case text[0]
		when '#start'
			# nil.to_i == 0
			start_new_game(text[1].to_i)
		when '#ban'
			if @game_in_progress
				@word_manager.ban(@current_word, @current_page)
				next_word
				@skipped += 1
			end
		when '#quit'
			Gtk.main_quit
		when '#name'
			@username = text[1]
		else
			word = text[0] || ""
			check_word(word)
		end
	end

	def start_new_game(length)
		if !@game_in_progress
			@game_in_progress = true
			@correct = 0
			@incorrect = 0
			@skipped = 0
			if length > 0
				@game_length = length
			else
				@game_length = AutoQuiz::DEFAULT_GAME_LENGTH
			end

			#prompt for username if not set
			unless @username
				dialog = Gtk::Dialog.new("We need names", @top_window, Gtk::Dialog::DESTROY_WITH_PARENT)#, [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT])
				entry = Gtk::Entry.new
				entry.set_max_length(100)
				dialog.vbox.add(Gtk::Label.new('Enter your name:'))
				dialog.vbox.add(entry)
				dialog.show_all
				entry.signal_connect('activate') {|e| @username = e.text; dialog.destroy }
				dialog.run
			end
			@start_time = Time.now
			next_word
		end
	end


	def end_game
		@game_in_progress = false
		@end_time = Time.now
		@rects = []
		@current_page = @doc.get_page(0)

		puts "Final score: #{@correct} correct, #{@incorrect} incorrect. (with #{@skipped} skipped)"
		puts "Time needed: #{(@end_time - @start_time).to_i}s"

		@highscore_manager.add_score(@username, @filename, @game_length, @correct, @skipped, (@end_time - @start_time).to_i)

		@top_window.queue_draw
	end

	def check_word(word)
		return unless @game_in_progress

		if word.downcase == @current_word.downcase
			@correct += 1
		else
			@incorrect += 1
			puts "Wrong! Correct word was: #{@current_word}"
		end

		if @correct + @incorrect < @game_length
			next_word
		else
			end_game
		end
	end
end

raise "Input file doesnt exist." if ARGV[0].nil? || !File.exist?(ARGV[0])
quiz = AutoQuiz.new(ARGV[0])

Gtk.main

class Word
	attr_reader :page, :text

	def initialize(page,  text)
		@page,  @text = page, text
	end

	def <=>(other)
		if @page != other.page
			return @page.<=>(other.page)
		else
			return @text.<=>(other.text)
		end
	end

	def eql?(other)
		@page == other.page && @text == other.text
	end
end

class AddressBook
  attr_reader :contacts

  def initialize
    begin
      @file = open('adresar.csv')
    rescue Errno::ENOENT
      p "Potřebuju adresar.csv"
      exit
    end
    @contacts = []
    read_book
  end

  def self.find(id)
    new.find(id)
  end

  def find(id)
    @contacts.select { |c| c.id == id.to_s}.first
  end

  private

  def parse_contacts(header, book)
    hashes = book.map { |contact| header.zip contact }.map(&:to_h)
    hashes.each { |c| @contacts << Contact.new(c) }
  end

  def read_book
    book = []
    File.open(@file, 'r') do |f|
      f.each_line do |line|
        book << line.delete("\n").split(';')
      end
    end
    header = book[0]
    book   = book[1..-1]
    parse_contacts(header, book)
  end
end

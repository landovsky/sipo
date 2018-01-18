# Description
class AddressBook
  attr_reader :contacts, :book

  BOOK = 'spec/fixtures/adresar.csv'.freeze

  def initialize
    @file     = load_book
    @contacts = without_dups
  end

  def self.find(id)
    new.find(id)
  end

  def find(id)
    find_all(id).first
  end

  private

  def find_all(id)
    @contacts.select { |c| c.id == id.to_s }
  end

  def without_dups
    contacts  = read_book
    ids       = contacts.map(&:id)
    dups      = ids.select { |id| ids.count(id) > 1 }.uniq
    return contacts if dups.empty?

    p 'Duplicitní kontakty nebudou zpracovány:'
    dups.each do |dup_id|
      contacts.each do |contact|
        p ' ' + contact.id + ': ' + contact.email if contact.id == dup_id
      end
    end

    contacts.reject { |contact| dups.include?(contact.id) }
  end

  def load_book
    open(BOOK)
  rescue Errno::ENOENT
    p 'Potřebuju adresář.csv'
    exit
  end

  def parse_contacts(header, book)
    hashes = book.map { |contact| header.zip contact }.map(&:to_h)
    hashes.map do |contact|
      params = symbolize_keys(contact)
      if Contact.valid?(params)
        Contact.new(params)
      else
        row = contact.values.compact.join(', ')
        p "Nepodařilo se zpracovat řádku adresáře: #{row}. Je správně oddělen středníkem?"
        next
      end
    end.compact
  end

  def symbolize_keys(hsh)
    {}.tap do |new_hash|
      hsh.each_pair do |key, value|
        new_hash[key.to_sym] = value
      end
    end
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

#!/usr/bin/env ruby

## MVP (demo)
# seznam id a emailu
# poslani emailu s telem a prilohou
# kompilace do exe
# cesty ve Windows

## TODOs
# system clear / cls
# kompilace do exe
# zpracovane prejmenovat

require 'pry'
require 'dry-types'
require 'dry-struct'
require 'dry-validation'
require 'mail'

lib_path = File.expand_path('lib', File.dirname(__FILE__))
$LOAD_PATH.unshift lib_path
Dir["#{lib_path}/*.rb"].each { |file| require file }
Dir["#{lib_path}/mailer/*.rb"].each { |file| require file }

# Desc
module SipoMailer
  class << self
    def config
      @config
    end

    def address_book
      @address_book
    end
  end

  @config       ||= Config.new
  @address_book ||= AddressBook.new

  def self.perform
    files = Dir[Dir.pwd + '/*.*'] #.each { |file| p file }
    files = files.map { |path| Attachment.new(path) }.select(&:valid?)
    files = files.reject { |file| file.processed? }

    if files.none?    
      printf "Žádné soubory ke zpracování\n"
      exit
    end

    printf "Našel jsem %d souborů ke zpracování.\n\n", files.count

    files = files.reject do |file|
      if SipoMailer.address_book.find(file.id).nil?
        printf "Vyřazuji soubor #{file.filename}, číslo #{file.id} nenalezeno v adresáři.\n\n"
        true
      else
        false
      end
    end

    response = nil
    until %w(a n).include?(response)
      printf "Poslat %s soubor/ů?\n", files.count
      print "(a) ano\n"
      print "(n) ne\n"

      response = STDIN.gets.strip
      exit if response == 'n'
      system('clear')
    end

    files.each do |file|
      to = SipoMailer.address_book.find(file.id).email
      printf 'Posílám soubor %s na %s', file.filename, to

      email = Email.send(to: to, attachment: file)
      print "  ok\n\n" if email.sent?
    end
  end
end

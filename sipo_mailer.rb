#!/usr/bin/env ruby

## MVP (demo)
# seznam id a emailu
# poslani emailu s telem a prilohou
# kompilace do exe
# cesty ve Windows

## Proces
# overim ze mam AddressBook
# hledam soubory v current dir
# kazdy nezpracovany
# => nacist prijemce
# => sestavit email
# => pridat prilohu
# => poslat (synchronne)
# https://stackoverflow.com/questions/12884711/how-to-send-email-via-smtp-with-rubys-mail-gem
# zpracovane prejmenovat

$LOAD_PATH.unshift '/app'

require 'pry'
require 'dry-types'
require 'dry-struct'
require 'dry-validation'
require 'mail'

Dir['/app/lib/*.rb'].each { |file| require file }
Dir['/app/lib/mailer/*.rb'].each { |file| require file }

# Desc
class SipoMailer
  def self.perform
    Mailer::Config.setup
    
    ARGV.each do |a|
      puts "Argument: #{a}"
    end

    Timer.elapsed do
      files = Dir[Dir.pwd + '/*.*'].each { |file| p file }
      files = files.map { |path| Attachment.new(path) }
      p('Žádné soubory ke zpracování') and exit unless files.any?(&:valid?)
    end
  end
end

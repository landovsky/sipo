#!/usr/bin/env ruby

$:.unshift '/app'

require 'pry'
require 'lib/address_book'
require 'lib/attachment'

## MVP (demo)
# diakritika
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

ARGV.each do|a|
  puts "Argument: #{a}"
end

p Dir.pwd
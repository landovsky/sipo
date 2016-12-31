prompt = "> "
puts "Které období zpracovat?"
print prompt
while input = gets.chomp
  system "clear"
  case
  when input == "q"
    puts "Konec programu"
    break
  else
    begin
      a = input.to_i
    rescue
      puts "Nedaří se konverze do čísla"
      raise
    end
  end
  case
  when a.between?(1,12)
    puts "zpracovává se období #{a}"
    break
  else
    puts "zkuste zadat číslo mezi 1 a 12"
  end
end
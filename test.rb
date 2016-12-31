system "clear"
prompt = "> "
puts "Please select 1, 2 or q(uit):"
print prompt

while user_input = gets.chomp # loop while getting user input
  case
  when user_input === "1"
    puts "First response (#{user_input})"
    puts "job done....press any key to continue"
    #break # make sure to break so you don't ask again
  when user_input === "2"
    puts "Second response (#{user_input})"
    puts "job done....press any key to continue"
    #break # and again
  when user_input === "q"
    puts "Exit (#{user_input})"
    break # and again    
  else
    system "clear"
    puts "You entered #{user_input}"
    puts "Please select 1, 2 or q(uit):"
    print prompt # print the prompt, so the user knows to re-enter input
  end
end
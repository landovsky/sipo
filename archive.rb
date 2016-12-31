#OLD CODE
#ZMENA soubor - ROO
if options[:change] && options[:roo] then
  
xls = Roo::Spreadsheet.open(file, extension: :xls)

data = Hash.new
cols = Array.new
config = Config.new.zmena

y = 1

config.keys.each do |key| #cycle to go through all columns defined by config
  cols[y] = Col.new(config[key]) #create data column in cols array
  for x in 2..xls.column(y).size do
    #1.. > bez záhlaví, 0.. > se záhlavím
    cols[y].value=xls.formatted_value(x,y) #insert value from each row of column
    data[[y,x-1]]=(cols[y].out) #output formatted data to data hash
  end
  y += 1
end

data_out = HashExport.new(data) #export data from hash to table

if options[:screen] #output on screen or write to file
  #puts data
  puts "\nZměnový soubor"
  puts data_out.export
else
  output = File.new("ZM#{CreateData.new.organization_number}.TXT", "w")
  if output
    output.syswrite(data_out.export.encode!(Encoding::Windows_1250)) #encode
    puts "Soubor #{output} zapsán."
    else
      Puts "nemůžu otevřít soubor"
      end  
  output.close
end
end

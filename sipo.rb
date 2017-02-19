require 'roo-xls'
require 'optparse'
require 'test/unit'
require 'simple-spreadsheet'
require_relative 'sipo-classes.rb'

#TO-DO
# - zavést kontrolu na očekávaný obsah excelu pro :compare
# - testy na celé bloky kódu

#do tříd

ORG_NUMBER = 112882

options = {}

OptionParser.new do |parser|
  parser.on("-o", "--obrazovka", "Výstup na obrazovku.") do |v| options[:screen] = v end
  parser.on("-z", "--zmena", "Zpracování změnového XLS souboru do TXT.") do |v| options[:change] = v end
  parser.on("-p", "--platby", "Zpracování změnového TXT souboru do XLS.") do |v| options[:paid] = v end
  parser.on("-s", "--oddelovace", "Zobrazit _ pro mezery a | pro sloupce.") do |v|options[:display] = v end
  parser.on("-c", "--compare", "Detekce zmen v Excelu pro dum.") do |v|options[:compare] = v end
end.parse!

#FORMATOVANI pro obrazovku
if options[:display] then
  SEPARATOR = '_'
  COLUMN = '|'
  elsif
    SEPARATOR = ' '
    COLUMN = ''
end

#ZMENA soubor
if options[:change] then
  original_warning_level = $VERBOSE
  $VERBOSE = nil
  xls = SimpleSpreadsheet::Workbook.read(FileCheck.new("xls,xlsx").do)
  $VERBOSE = original_warning_level
  data = Hash.new
  cols = Array.new
  config = Config.new.zmena
  x = 1 #column number
   
  config.keys.each do |key| #cycle through all columns defined by config as "key"
    2.upto(xls.last_row) do |y| #2 >> předpokládá se, že dodaný soubor má záhlaví
      begin
        data[[x,y-1]] = Col.new(config[key],xls.cell(y,x),y).out
      rescue ArgumentError => e
        puts "chyba: #{e}"
        abort
      end
    end
    x += 1
  end

  out = HashExport.new(data)
  if options[:screen] then #output on screen or write to file
  #puts data
    puts "\nZměnový soubor"
    puts out.export
    puts "\nZáznamů: #{out.rows}"
  else
    FileSave.new("ZM#{CreateData.new.organization_number}.TXT", out.export)
    Dispatch.new(CreateData.new.organization_number,CreateData.new.current_month,out.rows,options)
  end
end

#PLATBY
if options[:paid] then
  config = Config.new.prijate_platby
  req_size = 1 #zahrnuje "\n"
  config.each_key do |key| #sečte délku polí dle konfigurace = délka řádku
    req_size += config[key][1]
  end
  f = File.open(FileCheck.new("txt").do, "r") 
  p = 1 #pointer
  lines = Array.new 
  data = Hash.new
  f.each_line do |line| #procházím řádky souboru
    raise "Délka řádku #{p} je #{line.size} a neodpovídá požadované délce (#{req_size}): #{line}" unless line.size == req_size
    beg = 0
    lp = 1
    line.delete!("\n")
    cols = Array.new
    config.each_key do |key| #zpracovávám řádky souboru
      #print "#{config[key][0]} (#{config[key][1]}): "
      #print "(#{p},#{lp}) #{line[beg..beg+config[key][1]]} "
      #data[[lp,p]] = "#{beg}.." + line[beg..beg+config[key][1]-1] + " (" + line[beg..beg+config[key][1]].delete("\n").size.to_s + ")" + "..#{beg+config[key][1]}"
      cols[p] = Col.new(config[key])
      val = line[beg..beg+config[key][1]-1]
      val = val.to_i if val.include?(".00")
      data[[lp,p]] = val
      beg += config[key][1]
      lp += 1
    end
    p += 1
  end
  f.close
  data_out = HashExport.new(data,",")
  puts data_out.export
end

#Detekce změn
while options[:compare] do
  original_warning_level = $VERBOSE
  $VERBOSE = nil
  xls = SimpleSpreadsheet::Workbook.read(FileCheck.new("xls,xlsx").do)
  $VERBOSE = original_warning_level
  xls.selected_sheet = xls.sheets[0]
  org_number = sprintf("%d",xls.cell(1,8))
  xls.selected_sheet = xls.sheets[2]
  
  def prompt
    prompt = "> "
    puts "\nKteré období zpracovat?"
    print prompt
    while input = STDIN.gets
      input ||= ''
      input.chomp!
      system "clear"
      case
      when input == "q"
        puts "Konec programu"
        abort
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
        break
      else
        puts "Zkuste zadat číslo mezi 1 a 12, (nebo \"q\" k ukončení):"
      end
    end
    return a
  end
  
  selection = prompt
    
  #cell(y,x)    
  org_number_sheet = 1
  col_base_month = 6
  offset = 2
  col_current_month = col_base_month + (offset * (selection-1))
  period = ConvertToPeriod.new(selection).do
  fee_type = '210'


  
  #detekce řádků se změnou
  puts "\nKontroluju sloupec #{xls.cell(1,col_current_month)}"
  check_rows = Array.new
  2.upto(xls.last_row) do |y|
    curr_val = xls.cell(y,col_current_month)
    prev_val = xls.cell(y,col_current_month-offset)
    sipo = xls.cell(y,2)
    next if curr_val == prev_val
    next if curr_val == nil || prev_val == nil
    next if curr_val.respond_to?(:downcase) || prev_val.respond_to?(:downcase)
    next if sipo == nil
    check_rows.push(y)
  end
  
  #výroba dat
  config = Config.new.zmena
  data = Hash.new
  y = 1
  #cyklus přes položky změn
  check_rows.each do |row|
    data[[1,y]] = Col.new(config[:oz],'',row).out
    data[[2,y]] = Col.new(config[:obdobi],period,row).out
    data[[3,y]] = Col.new(config[:indikace_zmeny],2,row).out
    data[[4,y]] = Col.new(config[:spojovaci_cislo],xls.cell(row,2),row).out
    data[[5,y]] = Col.new(config[:cislo_organizace],org_number,row).out
    data[[6,y]] = Col.new(config[:prazdne_pole],'',row).out
    data[[7,y]] = Col.new(config[:kod_poplatku],fee_type,row).out
    data[[8,y]] = Col.new(config[:predpis],xls.cell(row,col_current_month),row).out
    data[[9,y]] = Col.new(config[:puvodni_predpis],'',row).out
    data[[10,y]] = Col.new(config[:text],"text na doklad",row).out
    y += 1
  end
    
  if check_rows == []
    puts "Žádné změny"
    redo
    else
      if options[:screen] then #output on screen or write to file
        puts HashExport.new(data).export
      else
        puts "Našel jsem rozdíl v #{CzechForms.new(check_rows.size,"záznamu","záznamech").do}."
        FileSave.new("ZM#{org_number}.TXT", data)
        Dispatch.new(org_number,selection,check_rows.size,options)
        redo
      end
  end
end

puts "\n"
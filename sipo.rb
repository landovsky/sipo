require 'roo-xls'
require 'optparse'
require 'test/unit'
require 'simple-spreadsheet'

#TO-DO
# - zavést kontrolu na očekávaný obsah excelu pro :compare
# - testy na celé bloky kódu

#do tříd

ORG_NUMBER = 112062

options = {}

OptionParser.new do |parser|
  parser.on("-o", "--obrazovka", "Výstup na obrazovku.") do |v| options[:screen] = v end
  parser.on("-z", "--zmena", "Zpracování změnového XLS souboru do TXT.") do |v| options[:change] = v end
  parser.on("-p", "--platby", "Zpracování změnového TXT souboru do XLS.") do |v| options[:paid] = v end
  parser.on("-s", "--oddelovace", "Zobrazit _ pro mezery a | pro sloupce.") do |v|options[:display] = v end
  parser.on("-c", "--compare", "Detekce zmen v Excelu pro dum.") do |v|options[:compare] = v end
end.parse!

class CzechForms
  def initialize (number,first_form,plural_form='',third_form='')
    @number = number
    third_form = plural_form if third_form == ''
    case
    when @number == 1
      @word = first_form
    when @number.between?(2,4)
      @word = plural_form
    else
      @word = third_form
    end
  end
  def do
    @out = @number.to_s + ' ' + @word
  end
end
class Col
  attr_accessor :value
  def initialize(params,value='',y="n/a")
    @value = value
    @name = params[0]
    @length = params[1]
    @decimals = params[2]
    @mandatory = params[3]
    @full = params[4]
    @align = params[5]
    @y = y
  end
  def out
    decimals = "" if @decimals == 0
    decimals = "," + 0.to_s * @decimals if @decimals > 0 #preparation of format for sprintf
    @value = sprintf("%d#{decimals}",@value) if @value.respond_to?(:floor) #format decimals if value is a number
    raise ArgumentError.new("sloupec \"#{@name}\", řádek #{@y}: hodnota nesmi byt prazdna") if @value.to_s.length == 0 && @mandatory == true
    raise ArgumentError.new("sloupec \"#{@name}\", řádek #{@y}: hodnota #{@value} nesplnuje pozadovanou delku") if @value.to_s.length < @length && @full == true
    raise ArgumentError.new("sloupec \"#{@name}\", řádek #{@y}: hodnota #{@value} ve sloupci #{self} nesmi byt delsi nez #{@length}") if @value.to_s.length > @length
    if @align == :right then @value = SEPARATOR * (@length - @value.to_s.length) + @value.to_s + COLUMN
      else @value = @value.to_s + SEPARATOR * (@length - @value.to_s.length) + COLUMN
      end
    @value
  end
end  
class FileCheck
  def initialize (allowed_types)
    begin
      raise RuntimeError.new if ARGV == []
      @allowed = allowed_types.split(",")
      @file = ARGV[0]
      @filetype = Array.new
      @filetype = @file.split(".")
      @filetype = @filetype[1].downcase
      raise IOError.new unless @allowed.include?(@filetype)
    rescue RuntimeError
      puts "Končím, protože nemám žádný soubor ke zpracování.\n"
      abort
    rescue IOError
      puts "S tímhle souborem to nepůjde (#{@file}). Podporuju jen soubory typu #{@allowed}.\n"
      abort
    end
  end
  def do
    @file
  end
end
class FileSave
  def initialize (filename,content)
    @filename = filename
    @content = content
    begin
      output = File.new(@filename, "w")
      @content = HashExport.new(@content).export if @content.class == Hash
      output.syswrite(@content.encode!(Encoding::Windows_1250)) #encode
      puts "\nSoubor #{@filename} zapsán."
    rescue
      puts "\nNěco se nepovedlo. Soubor není zapsán."
      raise
    end  
    output.close
  end
end
class ConvertToPeriod
  def initialize (selection)
    @selection = selection
    @year = Date.today.strftime("%Y").to_i
    @year = Date.today.strftime("%Y").to_i + 1 if @selection == 1
    @period = @selection.to_s.rjust(2, '0') + @year.to_s
    puts "\nPředpokládám, že export je za 01/#{@year}." if @selection == 1
  end
  def do
    @period
  end
end
class Dispatch
  def initialize (org_number,month,rows,options)
    @org_number = org_number
    @month = month
    @rows = rows
    @options = options
    #puts "org_no #{@org_number}, month: #{@month}, rows: #{@rows}, options: #{@options}"
    data = Hash.new
    config = Config.new.zmena_pruvodka
    data[[1,1]] = Col.new(config[:cislo_organizace],@org_number).out
    data[[2,1]] = Col.new(config[:obdobi],ConvertToPeriod.new(@month).do).out
    data[[3,1]] = Col.new(config[:pocet_vet],@rows).out
    data[[4,1]] = Col.new(config[:datum_vytvoreni],CreateData.new.created_date).out
  
    if @options[:screen] #output on screen or write to file
      puts "\nPrůvodka změnového souboru"
      puts HashExport.new(data).export
    else
      FileSave.new("OP#{@org_number}.TXT", data)
    end
  end
end
class HashExport  
  def initialize(data,separator="")
    @data = data
    @separator = separator
    @size = Array.new(@data.each_key.max)
    @xx = @size[0] #columns
    @yy = @size[1] #rows
  end
  def export
    output = ''
    separator = @separator
    for y in 1..@yy do
      for x in 1..@xx do
        separator = "\r\n" if x == @xx
        output += @data[[x,y]].to_s + separator
      end 
      #output += "\r\n"
      separator = @separator
    end
    return output
  end
  def rows
    @yy
  end 
end
class CreateData
  def current_month
    Date.today.strftime("%m")
  end
  def organization_number
    ORG_NUMBER
  end
  def created_date
    Date.today.strftime("%d%m%Y")
  end
end
class Config
  def initialize
    @config = Hash.new() #nazev, delka, počet desetinných míst čísel, povinnost, vyplňuje celou délku, zarovnání
  end
  def zmena
    @config[:oz] = ["odstepny zavod",2,0,false,false,:right]
    @config[:obdobi] = ["obdobi",6,0,true,true]
    @config[:indikace_zmeny] = ["indikace zmeny",1,0,true,false,:right]
    @config[:spojovaci_cislo] = ["spojovaci cislo",10,0,true,true]
    @config[:cislo_organizace] = ["cislo organizace",6,0,true,true]
    @config[:prazdne_pole] = ["prazdne pole",6,0,false,false,:right]
    @config[:kod_poplatku] = ["kod poplatku",3,0,true,false,:right]
    @config[:predpis] = ["predpis",9,2,true,false,:right]
    @config[:puvodni_predpis] = ["puvodni predpis",12,2,false,false,:right]
    @config[:text] = ["text dokladu",18,0,false,false,:left]
    @config
  end
  def zmena_pruvodka
    @config[:cislo_organizace] = ["cislo organizace",6,0,true,true]
    @config[:obdobi] = ["obdobi",6,0,true,true]
    @config[:pocet_vet] = ["pocet vet",8,0,true,false,:right]
    @config[:datum_vytvoreni] = ["datum vytvoreni",8,0,true,true]
    @config
  end
  def prijate_platby
    @config[:cislo_organizace] = ["cislo organizace",6,0,true,true]
    @config[:spojovaci_cislo] = ["spojovaci cislo",10,0,true,true]
    @config[:obdobi] = ["obdobi",6,0,true,true]
    @config[:kod_poplatku] = ["kod poplatku",3,0,true,false,:right]
    @config[:platba] = ["platba",9,2,true,false,:right]
    @config[:datum_podani] = ["datum podani",10,0,true,true]
    @config
  end
end

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
    cols[x] = Col.new(config[key]) #create data column in cols array
    2.upto(xls.last_row) do |y|
      cols[x].value = xls.cell(y,x)
      data[[x,y-1]] = cols[x].out #output formatted data to data hash
    end
    x += 1
  end

  if options[:screen] then #output on screen or write to file
  #puts data
    puts "\nZměnový soubor"
    puts HashExport.new(data).export
  else
    FileSave.new("ZM#{CreateData.new.organization_number}.TXT", data)
    Dispatch.new(CreateData.new.organization_number,CreateData.new.current_month,xls.last_row,options)
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
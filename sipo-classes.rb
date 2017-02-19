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
    decimals = "." + 0.to_s * @decimals if @decimals > 0 #preparation of format for sprintf
    @value = sprintf("%d#{decimals}",@value) if @value.respond_to?(:floor) #format decimals if value is a number
    raise ArgumentError.new("sloupec \"#{@name}\", řádek #{@y}: hodnota nesmi byt prazdna") if @value.to_s.length == 0 && @mandatory == true
    raise ArgumentError.new("sloupec \"#{@name}\", řádek #{@y}: hodnota #{@value} nesplnuje pozadovanou delku (#{@length})") if @value.to_s.length < @length && @full == true
    raise ArgumentError.new("sloupec \"#{@name}\", řádek #{@y}: hodnota #{@value} nesmi byt delsi nez #{@length}") if @value.to_s.length > @length
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
  
    FileSave.new("OP#{@org_number}.TXT", HashExport.new(data).export)
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
    Date.today.next_month.strftime("%m")
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
    @config[:puvodni_predpis] = ["puvodni predpis",9,2,false,false,:right]
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

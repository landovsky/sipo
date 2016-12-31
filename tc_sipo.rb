begin
  require_relative 'sipo'
rescue LoadError
  raise LoadError.new ("Cannot load SIPO")
end

require 'test/unit'


class TestCol < Test::Unit::TestCase
  def setup
    @config = Hash.new
    @config[:obdobi] = ['obdobi',6,0,true,true]
    @config[:predpis] = ['predpis',10,2,true,false,:right]
    @config[:predpis2] = ['predpis2',10,1,true,false,:right]    
    @config[:text] = ['text dokladu',10,0,false,false,:left]
  end
  def test_input_errors
    assert_raise(ArgumentError) {Col.new(@config[:obdobi],'').out}
    assert_raise(ArgumentError) {Col.new(@config[:obdobi],'12345').out}
    assert_raise(ArgumentError) {Col.new(@config[:obdobi],'1234567').out}
  end
  def test_output
    assert_equal('123456', Col.new(@config[:obdobi],123456).out)
    assert_equal('123456', Col.new(@config[:obdobi],123456.0).out)
    assert_equal('   1000,00', Col.new(@config[:predpis],1000).out)
    assert_equal('    1000,0', Col.new(@config[:predpis2],1000).out)
    assert_equal('doklad    ', Col.new(@config[:text],'doklad').out)
  end
end

class TestHashExport < Test::Unit::TestCase
  def setup
    @data = Hash.new
    @data[[1,1]] = "a"
    @data[[1,2]] = "b"
    @data[[2,1]] = "c"
    @data[[2,2]] = "d"
  end
  def test_export
    assert_equal("ac\r\nbd\r\n", HashExport.new(@data).export)
    assert_equal("a,c\r\nb,d\r\n", HashExport.new(@data,",").export)
  end
end

class TestConvertToPeriod
  def test_conversion
    assert_equal("012017", ConvertToPeriod.new(1).do)
  end
end
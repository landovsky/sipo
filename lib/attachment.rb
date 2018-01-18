# Description
class Attachment
  FILENAME_REGEX = /^[0-9]+_?([0-9]{4}-[0-9]{2}-[0-9]{2})?\.[a-zA-Z0-9]+$/

  attr_reader :id, :file, :filename, :processed_on

  def initialize(filename)
    @file = open(filename)
    parse_meta
  end

  def valid?
    !(@filename =~ FILENAME_REGEX).nil?
  end

  def processed?
    !@processed_on.nil?
  end

  def process; end

  private

  def parse_meta
    @filename = @file.path.split('/').last
    name      = @filename.split('.').first
    try_date  = name.split('_')

    @id       = try_date.first
    @processed_on = try_date.last if try_date.size == 2
  end
end

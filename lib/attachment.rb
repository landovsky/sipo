class Attachment
  attr_reader :id, :file, :filename, :processed_on

  def initialize(filename)
    @file = open(filename)
    parse_meta
  end

  def processed?
    !@processed_on.nil?
  end

  def process

  end

  private

  def parse_meta
    @filename = @file.path.split('/').last
    name      = @filename.split('.').first
    try_date  = name.split('_')
    
    @id       = try_date.first
    @processed_on = try_date.last if try_date.size == 2
  end
end

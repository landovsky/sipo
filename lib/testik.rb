# Test
class Testik
  class Con
    def initialize
      init
      @con = 1
    end

    def init
    end
  end

  @config ||= Con.new

  class << self
    def con
      @config
    end
  end
end

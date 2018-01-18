class Contact
  attr_reader :id, :email

  def initialize(params)
    @id     = params.fetch('cislo')
    @email  = params.fetch('email')
  end
end

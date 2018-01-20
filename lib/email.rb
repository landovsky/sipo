# Mailer sender
class Email
  class DeliveryError < StandardError
  end

  class Response
    attr_reader :response
    def initialize(response = nil)
      @response = response
    end

    def sent?
      if @response.is_a? Mail
        @response&.errors.empty?
      else
        false
      end
    end
  end

  def initialize(to:, from:, subject:, attachment: nil)
    @to         = to
    @from       = from
    @subject    = subject
    @attachment = attachment
  end

  def self.send(to: 'landovsky@gmail.com',
                from: SipoMailer.config.env['FROM'],
                subject: 'ahoj',
                attachment: nil)
    email = new(to: to, from: from, subject: subject, attachment: attachment)
    begin
      response = email.send
      Response.new(response)
    rescue DeliveryError => e
      p e
    end
  end

  def send
    email.deliver!
  rescue SocketError
    print "\n\nChyba při posílání emailu: adresa " \
      "#{Mail.delivery_method.settings[:address]} není dostupná.\n"
    exit
  rescue Net::SMTPAuthenticationError
    print "\n\nChyba při posílání emailu: " \
      "chybné přihlašovací údaje pro emailovou schránku.\n"
    exit
  rescue Net::OpenTimeout
    print "\n\nChyba při posílání emailu: vypršel časový limit "\
      "při spojení s emailovým serverem.\n"
    exit
  end

  def email
    email         = Mail.new
    email.to      = @to
    email.from    = @from
    email.subject = @subject
    email.body    = email_body
    email.add_file(@attachment.path) if @attachment
    email
  end

  private

  def email_body
    'something simple'
  end
end

# Mailer sender
class Email
  # odeslani emailu
  # stav odesilani emailu

  class DeliveryError < StandardError
  end

  class Response
    attr_reader :response
    def initialize(response)
      @response = response
    end

    def sent?
      @response.errors.empty?
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
    email = Mail.new
    email.to = @to
    email.from = @from
    email.subject = @subject
    email.body = email_body
    email.add_file(@attachment.path) if @attachment
    begin
      email.deliver!
    rescue SocketError
      raise DeliveryError, "Chyba při posílání emailu: adresa #{Mail.delivery_method.settings[:address]} není dostupná."
    rescue Net::SMTPAuthenticationError
      raise DeliveryError, 'Chyba při posílání emailu: chybné přihlašovací údaje pro emailovou schránku.'
    rescue Net::OpenTimeout
      raise DeliveryError, 'Chyba při posílání emailu: vypršel časový limit při spojení s emailovým serverem.'
    end
  end

  private

  def email_body
    'something simple'
  end
end

require 'mail'

# Mailer config
module Mailer
  class Config
    def self.setup
      Mail.defaults do
        delivery_method :smtp, Config.options
      end
    end

    protected

    def self.options
      { address:              'smtp.gmail.com',
        port:                  587,
        domain:               'gmail.com',
        user_name:            'givit.cz@gmail.com',
        password:             '',
        authentication:       :login,
        enable_starttls_auto: true }
    end
  end
end

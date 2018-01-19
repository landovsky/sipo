# Config init
class Config
  attr_reader :env

  def initialize
    @env = env_load
    mailer_init
  end

  private

  def env_load
    file = open(File.expand_path('../.env', File.dirname(__FILE__)))
    raise '.env missing' unless file
    parse_dot_env(file)
  end

  def mailer_init
    options = email_options
    Mail.defaults { delivery_method :smtp, options }
  end

  def email_options
    {
      address:              'smtp.gmail.com',
      port:                  587,
      domain:               'gmail.com',
      user_name:            'givit.cz@gmail.com',
      password:             @env['EMAIL_PASSWORD'],
      authentication:       :login,
      enable_starttls_auto: true
    }
  end

  def parse_dot_env(file)
    envs = []
    File.open(file, 'r') do |f|
      f.each_line.each do |line|
        envs << line.delete("\n").split('=')
      end
    end
    envs.to_h
  end
end

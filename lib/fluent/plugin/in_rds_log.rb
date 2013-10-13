class Fluent::Rds_LogInput < Fluent::Input
  Fluent::Plugin.register_input("rds_log", self)

  config_param :tag,      :string
  config_param :host,     :string,  :default => nil
  config_param :port,     :integer, :default => 3306
  config_param :username, :string,  :default => nil
  config_param :password, :string,  :default => nil
  config_param :log_type, :string,  :default => nil
  config_param :refresh_interval, :integer, :default => 30
  config_param :auto_reconnect, :bool, :default => true

   def initialize
    super
    require 'mysql2'
  end

  def configure(conf)
    super
    if @log_type.empty?
      $log.error "fluent-plugin-rds-log: missing parameter log_type is {slow_log|general_log}"
    end
    begin
      @client = Mysql2::Client.new({
        :host => @host,
        :port => @port,
        :username => @username,
        :password => @password,
        :reconnect => @auto_reconnect
        :database => 'mysql'
      })
    rescue
      $log.error "fluent-plugin-rds-log: cannot connect RDS"
    end
  end

  def start
    super
    @watcher = Thread.new(&method(:watch))
  end

  def shutdown
    super
    @watcher.terminate
    @watcher.join
  end

  private
  def watch
    while true
      sleep @refresh_interval
      output
    end
  end

  def output
    @client.query("CALL mysql.rds_rotate_#{@log_type}")

    output_log_data = @client.query("SELECT * FROM mysql.#{@log_type}_backup", :cast => false)
    output_log_data.each do |row|
      row.delete_if{|key,value| value == ''}
      Fluent::Engine.emit(tag, Fluent::Engine.now, row)
    end
  end
end

class Fluent::Rds_LogInput < Fluent::Input
  Fluent::Plugin.register_input("rds_log", self)

  config_param :tag,      :string
  config_param :host,     :string,  :default => nil
  config_param :port,     :integer, :default => 3306
  config_param :username, :string,  :default => nil
  config_param :password, :string,  :default => nil
  config_param :log_type, :string,  :default => nil
  config_param :refresh_interval, :integer, :default => 30

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
      sleep @interval
      output
    end
  end

  def output
    @client.query("CALL mysql.rds_rotate_#{@log_type}")
    @client.query("CREATE TEMPORARY TABLE mysql.output_log LIKE mysql.#{@log_type}_backup")

    output_log_data = []
    output_log_data = @client.query('SELECT * FROM mysql.output_log', :cast => false)

    output_log_data.each do |row|
      Fluent::Engine.emit(tag, Fluent::Engine.now, row)
    end
  end
end

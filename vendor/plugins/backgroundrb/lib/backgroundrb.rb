# Backgroundrb
# FIXME: check if data that we are writing to the socket should end with newline
require "pathname"
BACKGROUNDRB_ROOT = Pathname.new(RAILS_ROOT).realpath.to_s
require File.dirname(__FILE__) + "/../framework/bin_parser"
require File.dirname(__FILE__) + "/../framework/nbio"
require "bdrb_conn_error"

module BackgrounDRb
end
class BackgrounDRb::WorkerProxy
  include Packet::NbioHelper
  def self.init
    # @@config = YAML.load(File.open("#{BACKGROUNDRB_ROOT}/config/backgroundrb.yml"))
    @@config = YAML.load(ERB.new(IO.read("#{BACKGROUNDRB_ROOT}/config/backgroundrb.yml")).result)
    @@server_ip = @@config[:backgroundrb][:ip]
    @@server_port = @@config[:backgroundrb][:port]
    new
  end

  def establish_connection
    @tokenizer = BinParser.new
    begin
      timeout(3) do
        @connection = TCPSocket.open(@@server_ip, @@server_port)
        @connection.setsockopt(Socket::IPPROTO_TCP,Socket::TCP_NODELAY,1)
      end
      @connection_status = true
    rescue Timeout::Error
      @connection_status = false
    rescue Exception => e
      @connection_status = false
    end
  end

  def ask_work p_data
    p_data[:type] = :do_work
    establish_connection()
    raise BackgrounDRb::BdrbConnError.new("Not able to connect") unless @connection_status
    dump_object(p_data,@connection)
    # @connection.close
  end

  def new_worker p_data
    p_data[:type] = :start_worker
    establish_connection
    raise BackgrounDRb::BdrbConnError.new("Not able to connect") unless @connection_status
    dump_object(p_data,@connection)
    # @connection.close
  end

  def delete_worker p_data
    p_data[:type] = :delete_worker
    establish_connection
    raise BackgrounDRb::BdrbConnError.new("Not able to connect") unless @connection_status
    dump_object(p_data,@connection)
    # @connection.close
  end

  def send_data p_data
    begin
      @connection.write_nonblock(p_data)
    rescue Errno::EAGAIN
      return
    end
  end

  def read_object
    sock_data = ""
    begin
      while(sock_data << @connection.read_nonblock(1023)); end
    rescue Errno::EAGAIN
      @tokenizer.extract(sock_data) { |b_data| return b_data }
    rescue
      raise BackgrounDRb::BdrbConnError.new("Not able to connect")
    end
  end

  def query_all_workers
    p_data = { }
    p_data[:type] = :all_worker_status
    establish_connection
    raise BackgrounDRb::BdrbConnError.new("Not able to connect") unless @connection_status
    dump_object(p_data,@connection)
    begin
      ret_val = select([@connection],nil,nil,3)
      unless ret_val
        # @connection.close
        return nil
      end
      raw_response = read_object()
      master_response = Marshal.load(raw_response)
      # @connection.close
      return master_response
    rescue
      puts $!
      puts $!.backtrace
      # @connection.close
      return nil
    end
  end

  def ask_status(p_data)
    p_data[:type] = :get_status
    establish_connection()

    raise BackgrounDRb::BdrbConnError.new("Not able to connect") unless @connection_status
    dump_object(p_data,@connection)
    begin
      ret_val = select([@connection],nil,nil,3)
      unless ret_val
        # @connection.close
        return nil
      end
      raw_response = read_object()
      master_response = Marshal.load(raw_response)
      # @connection.close
      return master_response
    rescue
      puts $!
      puts $!.backtrace
      # @connection.close
      return nil
    end
  end

  def send_request(p_data)
    p_data[:type] = :get_result
    establish_connection()

    raise BackgrounDRb::BdrbConnError.new("Not able to connect") unless @connection_status
    dump_object(p_data,@connection)
    begin
      ret_val = select([@connection],nil,nil,nil)
      unless ret_val
        # @connection.close
        return nil
      end
      raw_response = read_object()
      master_response = Marshal.load(raw_response)
      # @connection.close
      return master_response[:data]
    rescue
      # @connection.close
      return nil
    end
  end
end

MiddleMan = BackgrounDRb::WorkerProxy.init


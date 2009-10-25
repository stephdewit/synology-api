require 'net/http'

require 'rubygems'
require 'json'

module SynologyApi
  
  class DownloadStation
    
    def initialize(address, port, user, password)
      @connection = Connection.new(address, port, user, password)
    end
    
  end
  
  class Connection
    
    def initialize(address, port, user, password)
      raise ArgumentError.new("Not nil 'address' argument expected") if address == nil
      raise ArgumentError.new("Not nil 'port' argument expected") if port == nil
      raise ArgumentError.new("Not nil 'user' argument expected") if user == nil
      raise ArgumentError.new("Not nil 'password' argument expected") if password == nil
      
      cleaned_address = address.strip
      raise ArgumentError.new("Not empty 'address' argument expected") if cleaned_address.empty?
      
      raise TypeError.new("Integer 'port' argument expected") if not port.is_a? Integer
      
      cleaned_user = user.strip
      raise ArgumentError.new("Not empty 'user' argument expected") if cleaned_user.empty?

      @http = Net::HTTP.new(cleaned_address, port)
      @user = cleaned_user
      @password = password
      
      @token = nil
    end
    
    def address
      if @http
        @http.address
      end
    end
    
    def port
      if @http
        @http.port
      end
    end
    
    attr_reader :user

    def login
      logout
      
      result = send({'action' => 'login', 'username' => @user, 'passwd' => @password}, false)
      raise LoginFailedError.new("Login failed for user #{@user}") unless result['login_success']
      
      @token = result['id']
    end
    
    def logout
      @token = nil
    end
      
    def is_connected?
      @token != nil
    end
    
    DOWNLOADREDIRECTOR_PATH = '/download/download_redirector.cgi'
    
    def send(data, add_token=true)
      raise ArgumentError.new("Not nil 'data' argument expected") if data == nil
      raise TypeError.new("Hash 'data' argument expected") if not data.is_a? Hash
      raise ArgumentError.new("Not empty 'data' argument expected") if data.empty?
      
      login if (add_token && !is_connected?)
      
      if add_token
        data_to_add = { 'id' => @token }
      else
        data_to_add = {}
      end
      
      request = Net::HTTP::Post.new(DOWNLOADREDIRECTOR_PATH)
      request.set_form_data(data_to_add.merge(data))
      
      begin
        response = @http.start { |h| h.request(request) }
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT => x
        exception = NetworkError.new("Can't connect to server: #{x.message}")
        exception.inner_exception = x
        raise exception
      end
      
      response.error! if not response.is_a? Net::HTTPSuccess
      
      result = JSON.parse(response.body)
      # TODO: be more specific
      raise DownloadStationError.new('Something went wrong while processing query') unless result['success']
      
      result
    end
    
    # FIXME
    # Couldn't find a gem which handles multipart POSTs correctly
    # Why the hell can't Net::HTTP do that ??!?
    def upload_torrent_file(file)
      curl_stdout = `curl -F "id=#{@id}" -F "torrent=@#{file}" http://#{@connection.address}:#{@connection.port}#{DOWNLOADREDIRECTOR_PATH}`
      
      JSON.parse(curlStdOut)
    end
    
  end
  
  class Command
    
    def execute(connection)
      
    end
    
  end

  class LoginCommand < Command

  end

  class AuthentifiedCommand < Command

  end

  class ActionCommand < AuthentifiedCommand

  end
  
  class UploadCommand < AuthentifiedCommand

  end

  class DownloadStationError < StandardError; end
  
  class NetworkError < DownloadStationError
    attr_accessor :inner_exception
  end
  
  class LoginFailedError < DownloadStationError; end
end
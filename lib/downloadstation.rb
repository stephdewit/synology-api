require 'errors'
require 'connection'

module SynologyApi
  
  module DownloadStation
  
    class DownloadStation
    
      def initialize(address, port, user, password)
        @connection = Connection.new(address, port, user, password)
      end
    
      def jobs
        response = @connection.send('action' => 'getall')
        
        if response && response['items']
          response['items'].map { |j| Job.new(j) }
        else
          []
        end
      end
    
    end
    
    class Job
      
      def initialize(data)
        raise ArgumentError.new("Not nil 'data' argument expected") if data == nil
        raise TypeError.new("Hash 'data' argument expected") if not data.is_a? Hash
        raise ArgumentError.new("Not empty 'data' argument expected") if data.empty?
        
        @data = data
      end
      
      # FIXME
      def method_missing(name, *args, &block)
        if @data && @data.has_key?(name.to_s)
          @data[name.to_s]
        else
          super
        end
      end
      
    end
  
    class DownloadStationError < SynologyApiError; end
  
  end
  
end

require 'errors'
require 'connection'

module SynologyApi
  
  module DownloadStation
  
    class DownloadStation
    
      def initialize(address, port, user, password)
        @connection = Connection.new(address, port, user, password)
      end
      
      attr_reader :connection
    
      def jobs
        response = @connection.send('action' => 'getall')
        
        if response && response['items']
          items = Jobs.new
          response['items'].each { |j| items << Job.new(j, self) }
          items
        else
          Jobs.new
        end
      end
      
      def create_job(url_or_file)
        raise ArgumentError.new("Not nil 'url_or_file' argument expected") if url_or_file == nil
        
        if !url_or_file.is_a?(String) && !url_or_file.is_a?(File)
          raise TypeError.new("String or File 'url_or_file' argument expected")
        end
        
        if (url_or_file.is_a? String)
          cleaned_url = url_or_file.strip
          raise ArgumentError.new("Not empty 'url' argument expected") if cleaned_url.empty?
        
          @connection.send('action' => 'addurl', 'url' => cleaned_url)
        else
          @connection.send('torrent' => url_or_file)
        end
      end
      
      def clear
        @connection.send('action' => 'clear')
      end
    
    end
    
    class Job
      
      def initialize(data, downloadstation)
        raise ArgumentError.new("Not nil 'data' argument expected") if data == nil
        raise TypeError.new("Hash 'data' argument expected") if not data.is_a? Hash
        raise ArgumentError.new("Not empty 'data' argument expected") if data.empty?
        
        raise ArgumentError.new("Not nil 'downloadstation' argument expected") if downloadstation == nil
        raise TypeError.new("DownloadStation 'downloadstation' argument expected") if not downloadstation.is_a? DownloadStation
        
        @data = data
        @downloadstation = downloadstation
      end
      
      def connection
        @downloadstation.connection
      end
      
      # FIXME
      def method_missing(name, *args, &block)
        if @data.has_key?(name.to_s)
          @data[name.to_s]
        else
          super
        end
      end
      
      def status
        return nil unless @data.has_key?('status')
        
        DownloadStatus.key(@data['status'])
      end
      
      def id
        @data['id']
      end
      
      def delete
        connection.send('action' => 'delete', 'idList' => id.to_s) # ID separator is ':'
      end
      
      def stop
        connection.send('action' => 'stop', 'idList' => id.to_s) # ID separator is ':'
      end
      
      def resume
        connection.send('action' => 'resume', 'idList' => id.to_s) # ID separator is ':'
      end
      
    end
    
    class Jobs < Array
      def total_download_speed
        inject(0) { |sum, j| sum + j.currentRate }
      end
      
      def total_upload_speed
        inject(0) { |sum, j| sum + j.uploadRate }
      end
    end
    
    class DownloadStatus
      
      def DownloadStatus.add_item(key, value)
        @hash ||= {}
        @hash[key] = value
      end

      def DownloadStatus.const_missing(key)
        @hash[key]
      end
      
      def DownloadStatus.key(value)
        @hash.index(value)
      end

      DownloadStatus.add_item :NEW, -1
      DownloadStatus.add_item :UNKNOWN, 0
      DownloadStatus.add_item :WAITING, 1
      DownloadStatus.add_item :DOWNLOADING, 2
      DownloadStatus.add_item :PAUSED, 3
      DownloadStatus.add_item :COMPLETED, 5
      DownloadStatus.add_item :CHECKING, 6
      DownloadStatus.add_item :SEEDING, 8
      DownloadStatus.add_item :ERROR, 101
      DownloadStatus.add_item :BROKENLINK, 102
      DownloadStatus.add_item :DOWNLOADFOLDERNOTFOUND, 103
      DownloadStatus.add_item :NOACCESSTODOWNLOADFOLDER, 104
      
    end
    
    class DownloadStationError < SynologyApiError; end
  
  end
  
end

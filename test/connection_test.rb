require 'test/unit'

require File.join(File.dirname(__FILE__), 'synologyapitest')
require File.join(File.dirname(__FILE__), '../lib/downloadstation.rb')

include SynologyApi

class ConnectionTest < Test::Unit::TestCase
  
  include SynologyApiTest
  
  skip_slow_tests = ENV['SKIP_SLOW_TESTS'] == '1'
  my_dns_sucks = ENV['MY_DNS_SUCKS'] == '1'
  
  def get_connection
    Connection.new(@address, @port, @user, @password)
  end
  
  private :get_connection
  
  def test_initialize
    connection = nil
    assert_nothing_thrown {
      connection = get_connection
    }
    
    assert_not_nil(connection)
    
    assert_equal(@address, connection.address)
    assert_equal(@port, connection.port)
    assert_equal(@user, connection.user)
  end
  
  def test_initialize_with_dirty_data
    connection = nil
    assert_nothing_thrown {
      connection = Connection.new("  \t#{@address}\r\n", @port, "\n\n#{@user} \n", @password)
    }
    
    assert_not_nil(connection)
    
    assert_equal(@address, connection.address)
    assert_equal(@port, connection.port)
    assert_equal(@user, connection.user)
  end
  
  def test_initialize_with_nil_address
    assert_raise(ArgumentError) {
      Connection.new(nil, @port, @user, @password)
    }
  end
  
  def test_initialize_with_nil_port
    assert_raise(ArgumentError) {
      Connection.new(@address, nil, @user, @password)
    }
  end
  
  def test_initialize_with_nil_user
    assert_raise(ArgumentError) {
      Connection.new(@address, @port, nil, @password)
    }
  end
  
  def test_initialize_with_nil_password
    assert_raise(ArgumentError) {
      Connection.new(@address, @port, @user, nil)
    }
  end
  
  def test_initialize_with_empty_address
    EMPTY_STRINGS.each { |s|
      assert_raise(ArgumentError) {
        Connection.new(s, @port, @user, @password)
      }
    }
  end
  
  def test_initialize_with_empty_user
    EMPTY_STRINGS.each { |s|
      assert_raise(ArgumentError) {
        Connection.new(@address, @port, s, @password)
      }
    }
  end
  
  def test_initialize_with_nonnumeric_port
    assert_raise(TypeError) {
      Connection.new(@address, 'foo', @user, @password)
    }
  end
  
  def test_send_with_nil_data
    assert_raise(ArgumentError) {
      get_connection().send(nil, false)
    }
  end
  
  def test_send_with_not_hash_data
    assert_raise(TypeError) {
      get_connection().send('bar', false)
    }
  end
  
  def test_send_with_empty_data
    assert_raise(ArgumentError) {
      get_connection().send({}, false)
    }
  end
  
  def test_send_junk_data
    begin
      get_connection().send({'thud' => 'foo'}, false)
    rescue => x
      assert_kind_of(SynologyApiError, x)
    end
  end
  
  def test_send_bad_command
    assert_raise(SynologyApiError) {
      get_connection().send({'action' => 'addurl', 'url' => 'bar'}, false)
    }
  end
  
  unless skip_slow_tests
    def test_send_with_bad_ip_address
      connection = nil
      assert_nothing_thrown {
        # I hope this IP address isn't used...
        connection = Connection.new('109.199.202.40', @port, @user, @password)
      }
    
      begin
        connection.send({'baz' => 'qux'}, false)
      rescue => x
        assert_kind_of(NetworkError, x)
        assert(!x.is_a?(HttpError))
        assert_kind_of(Errno::ETIMEDOUT, x.inner_exception)
        assert_equal(:ip_or_firewall, x.possible_cause)
      end
    end
  end
  
  unless my_dns_sucks
    def test_send_with_bad_dns_address
      connection = nil
      assert_nothing_thrown {
        # I hope this domain doesn't exist...
        connection = Connection.new('waldo.fred', @port, @user, @password)
      }
    
      begin
        connection.send({'plugh' => 'xyzzy'}, false)
      rescue => x
        assert_kind_of(NetworkError, x)
        assert(!x.is_a?(HttpError))
        assert_kind_of(SocketError, x.inner_exception)
        assert_equal(:dns, x.possible_cause)
      end
    end
  end
  
  def test_send_with_bad_port
    connection = nil
    assert_nothing_thrown {
      # I hope this TCP port isn't used...
      connection = Connection.new(@address, 45150, @user, @password)
    }
    
    begin
      connection.send({'quux' => 'corge'}, false)
    rescue => x
      assert_kind_of(NetworkError, x)
      assert(!x.is_a?(HttpError))
      assert_kind_of(Errno::ECONNREFUSED, x.inner_exception)
      assert_equal(:port, x.possible_cause)
    end
  end
  
  def test_login
    connection = nil
    
    assert_nothing_thrown {
      connection = get_connection()
      connection.login
    }
    
    assert connection.is_connected?
  end
  
  def test_login_with_bad_user
    connection = nil
    assert_nothing_thrown {
      connection = Connection.new(@address, @port, 'grault', @password)
    }
    
    assert_raise(LoginFailedError) {
      connection.login
    }
    
    assert !connection.is_connected?
  end
  
  def test_login_with_bad_password
    connection = nil
    assert_nothing_thrown {
      connection = Connection.new(@address, @port, @user, 'garply')
    }
    
    assert_raise(LoginFailedError) {
      connection.login
    }
    
    assert !connection.is_connected?
  end
  
  #def test_upload_torrent_file
  #  assert_nothing_thrown {
  #    get_connection().upload_torrent_file(File.join(File.dirname(__FILE__), 'debian-503-i386-businesscard.iso.torrent'))
  #  }
  #end

end

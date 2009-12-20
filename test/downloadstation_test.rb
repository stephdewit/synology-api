require 'test/unit'

require File.join(File.dirname(__FILE__), 'synologyapitest')
require File.join(File.dirname(__FILE__), '../lib/downloadstation.rb')

include SynologyApi::DownloadStation

class DownloadStationTest < Test::Unit::TestCase
  
  include SynologyApiTest
  
  def get_downloadstation
    DownloadStation.new(@address, @port, @user, @password)
  end
  
  private :get_downloadstation
  
  def test_initialize
    downloadstation = nil
    assert_nothing_thrown {
      downloadstation = get_downloadstation
    }
    
    assert_not_nil(downloadstation)
  end
  
  def test_initialize_job
    job = nil
    qux_value = 'quux'
    corge_value = 'grault'
    assert_nothing_thrown {
      job = Job.new({'qux' => qux_value, 'corge' => corge_value})
    }
    
    assert_not_nil(job)
    assert_equal(qux_value, job.qux)
    assert_equal(corge_value, job.corge)
  end
  
  def test_initialize_job_with_nil_data
    assert_raise(ArgumentError) {
      Job.new(nil)
    }
  end
  
  def test_initialize_job_with_not_hash_data
    assert_raise(TypeError) {
      Job.new('baz')
    }
  end
  
  def test_initialize_job_with_empty_data
    assert_raise(ArgumentError) {
      Job.new({})
    }
  end
  
  def test_get_jobs_list
    jobs = nil
    assert_nothing_thrown {
      jobs = get_downloadstation().jobs
    }
    
    assert_not_nil(jobs)
    assert_kind_of(Array, jobs)
  end
  
end

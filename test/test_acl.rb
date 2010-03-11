# -*- coding: utf-8 -*-
require 'helper'

# Extensions to Net::DAV::Item class:
class Net::DAV::Item

  def method_missing(sym, *args, &block)
    require 'pp'
    pp sym.to_s
    pp args[0]
  end

end

class TestVortexTags < Test::Unit::TestCase
  include Vortex

  def setup
    if(not(@vortex))
      user = ENV['DAVUSER']
      pass = ENV['DAVPASS']
      @vortex = Vortex::Connection.new("https://vortex-dav.uio.no/",user, pass)
    end
  end

  should "read access control lists for resource" do

    @vortex.cd('/brukere/thomasfl/nyheter/')
    @vortex.find('.', :filename => "my-sample-title.html") do |item|
      require 'pp'
      pp item
    end

  end

end

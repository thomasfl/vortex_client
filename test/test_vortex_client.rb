require 'helper'

class TestVortexClient < Test::Unit::TestCase

  should "open connection " do
    vortex = Vortex::Connection.new("https://vortex-dav.uio.no/")
    assert vortex
  end

end

# -*- coding: utf-8 -*-
require 'helper'

class TestVortexDateConversion < Test::Unit::TestCase
  include Vortex

  should "parse norwegian date and time formats" do
    assert norwegian_date('1.1.2010')
    assert norwegian_date('1.1.2010')
    assert norwegian_date('22.01.2010')
    assert norwegian_date('22.01.2010 12:15')
    assert norwegian_date('22.01.2010 12:15:20')
  end

end

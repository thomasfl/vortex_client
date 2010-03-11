# -*- coding: utf-8 -*-
require 'helper'

class TestVortexClientUtils < Test::Unit::TestCase
  include Vortex

  should "make sentence in to valid url withthout any url encoding" do
    assert_equal "hei-pa-deg", StringUtils.create_filename("Hei på deg")
    assert StringUtils.create_filename('áàâäãÃÄÂÀ') =~ /^a*$/
    assert StringUtils.create_filename('éèêëËÉÈÊ') =~ /^e*$/
    assert StringUtils.create_filename('íìîïIÎÌ') => /^i*$/
    assert StringUtils.create_filename('óòôöõÕÖÔÒ') => /^o*$/

    #      0000000001111111111222222222233333333334
    #      1234567890123456789012345678901234567890
    str = 'start! to ()[]{}__@__\/?/.,"§_»_%##!!!end;:stripped'
    assert_equal 'start-to-end', StringUtils.create_filename(str)
  end

end

require File.dirname(__FILE__) + '/../spec_helper'

include Rhino

module Foo
  attr_accessor :foo
end

class Obj
  include Foo
end

describe Rhino::RubyObject do  
  it 'allows you to access methods in an included module' do
    obj  = Obj.new
    robj = Rhino::RubyObject.new(obj)
    robj.send(:accessible_methods, true).should include(:foo)
    robj.send(:accessible_methods, true).should include(:foo=)
    robj.has('foo', robj).should be_true
    robj.put('foo', robj, 'bar')
    obj.foo.should == 'bar'
  end
  
  it 'does not allow you to access methods on Object' do 
    obj  = Obj.new
    robj = Rhino::RubyObject.new(obj)
    robj.send(:accessible_methods).should_not include(:clone)
    robj.has('clone', robj).should be_false
    robj.get('clone', robj).to_s.should include('NOT_FOUND')
  end
end

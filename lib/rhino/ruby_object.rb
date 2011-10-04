
module Rhino
  class RubyObject < J::ScriptableObject
    include J::Wrapper
    
    def initialize(object)
      super()
      @ruby = object
    end
    
    def unwrap
      @ruby
    end
    
    def getClassName()
      @ruby.class.name
    end
    
    def getPrototype()
      Prototype::Generic
    end
    
    def getIds()
      accessible_methods.map {|m| m.gsub(/(.)_(.)/) {java.lang.String.new("#{$1}#{$2.upcase}")}}.to_java
    end
        
    def to_s
      "[Native #{@ruby.class.name}]"
    end
    
    alias_method :prototype, :getPrototype
    
    def put(name, start, value)
      getter = "#{rb_name(name)}=".to_sym
      if accessible_methods(true).include?(getter) 
        @ruby.send(getter, value).to_java
      else
        super(name, start, value)
      end
    end

    def get(name, start)
      if name == "toString"
        return RubyFunction.new(lambda { "[Ruby #{@ruby.class.name}]" })
      end
      rb_name = rb_name(name)
      if (accessible_methods.include?(rb_name))
        method = @ruby.method(rb_name)
        if method.arity == 0
          To.javascript(method.call)
        else
          RubyFunction.new(method)
        end
      else
        super(name, start)
      end
    end

    def has(name, start)
      accessible_methods.include?(rb_name(name)) ? true : super(name, start)
    end
    
    private
    def rb_name(name)
      name.gsub(/([a-z])([A-Z])/) { "#{$1}_#{$2.downcase}" }.to_sym
    end
    # 
    # def public_methods
    #   @ruby.public_methods(false).collect(&:to_sym)
    # end
    # 
    def accessible_methods(special_methods = false)
      @ruby.public_methods(false).map {|m| m.to_s}.to_set.tap do |methods|
        ancestors = @ruby.class.ancestors.dup
        while ancestor = ancestors.shift
          break if ancestor == ::Object
          methods.merge(ancestor.public_instance_methods(false).map {|m| m.to_s})
        end
        methods.reject! {|m| m == "[]" || m == "[]=" || m =~ /=$/} unless special_methods
      end.collect(&:to_sym)
    end
    
    class Prototype < J::ScriptableObject
      Generic = new
    end
  end
end

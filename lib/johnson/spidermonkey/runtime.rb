module Johnson #:nodoc:
  module SpiderMonkey #:nodoc:
    class Runtime # native
      attr_reader :traps
      def initialize(options={})
        @debugger = nil
        @gcthings = {}
        @traps = []
        initialize_native(options)
      end
      
      # called from js_land_proxy.c:make_js_land_proxy
      def add_gcthing(thing)
        @gcthings[thing.object_id] = thing
      end
      
      # called from js_land_proxy.c:finalize
      def remove_gcthing(object_id)
        @gcthings.delete(object_id) if defined? @gcthings
      end

      def self.invoke_zero_arity= v; @invoke_zero_arity = v; end
      def self.invoke_zero_arity?; @invoke_zero_arity ||= false; end

      def current_context
        @context ||= Context.new(self)
      end

      def [](key)
        global[key]
      end
      
      def []=(key, value)
        global[key] = value
      end

      ###
      # Evaluate +script+ with +filename+ and +linenum+
      def evaluate(script, filename = nil, linenum = nil)
        compiled_script = compile(script, filename, linenum)
        evaluate_compiled_script(compiled_script)
      end

      def evaluate_compiled script
        evaluate_compiled_script(script)
        @traps.each do |trap_tuple|
          clear_trap(*trap_tuple)
        end
      end

      ###
      # Compile +script+ with +filename+ and +linenum+
      def compile(script, filename=nil, linenum=nil)
        filename ||= 'none'
        linenum  ||= 1
        native_compile(script, filename, linenum)
      end

      def current_stack
        evaluate('(function () { try { null.null(); } catch (ex) { return ex.stack; } })()')
      end

      # WARNING: This function is currently invoked unprotected from C;
      # if it raises or throws, Ruby WILL segfault. And that's Bad.
      def add_boundary_stacks(ex, ruby_skip=0)
        if ex.instance_variable_defined?(:@spidermonkey_boundary_stacks)
          list = ex.instance_variable_get(:@spidermonkey_boundary_stacks)
        else
          list = ex.instance_variable_set(:@spidermonkey_boundary_stacks, [])
        end

        list << [:js, self.current_stack]
        list << [:ruby, caller(ruby_skip + 1)]

      rescue Object
      end

      def raise_above(ex, up)
        ex.set_backtrace caller(up + 1)
        raise ex
      end

      def raise_js_exception(jsex)
        case jsex
        when Exception
          raise jsex
        when String
          raise_above Johnson::Error.new(jsex), 2
        when Johnson::SpiderMonkey::RubyLandProxy
          message = jsex['message'] || jsex.to_s
          raise_above Johnson::Error.new(message, jsex), 2
        else
          raise_above Johnson::Error.new(jsex.inspect), 2
        end
      end
    end
  end
end

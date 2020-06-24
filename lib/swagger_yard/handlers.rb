module SwaggerYard::Handlers
  class DSLHandler < YARD::Handlers::Ruby::Base
    include YARD::CodeObjects
    namespace_only

    def self.method_options
      @method_options ||= {}
    end

    def self.reset
      method_options.keys.each do |m|
        handler = handlers.detect { |h| h.respond_to?(:name) && h.send(:name).to_s == m.to_s }
        handlers.delete handler if handler
      end
      method_options.clear
    end

    def self.register_dsl_method(name, options = {})
      return if self.method_options[name.to_s]
      options[:args] ||= 0..-1
      self.method_options[name.to_s] = options
      handles method_call(name)
    end

    def process
      options = self.class.method_options[caller_method]
      return unless options
      call_params[options[:args]].each do |method_name|
        object = MethodObject.new(namespace, method_name, scope)
        object.signature = "def #{method_name}"
        register(object)
      end
    end
  end

  class RSpecDescribeHandler < YARD::Handlers::Ruby::Base
    handles method_call(:describe)

    process do
      method_name = statement.parameters.first.jump(:string_content).source
      # pretend as class to have #children method
      # TODO subclass it in DescribeObject
      object = ClassObject.new(namespace, method_name)
      register(object)
      parse_block(statement.last.last, owner: object)
    end
  end

  class RSpecItHandler < YARD::Handlers::Ruby::Base
    handles method_call(:it)

    def process
      return if owner.nil?

      method_name = statement.parameters.first.jump(:string_content).source
      object = MethodObject.new(namespace, method_name, scope)
      register(object)
      owner.children << object
    end
  end
end

require 'set'
module ActiveModel
  class SerializableResource
    ADAPTER_OPTION_KEYS = Set.new([:include, :fields, :adapter, :meta, :meta_key, :links])

    # Primary interface to composing a resource with a serializer and adapter.
    # @return the serializable_resource, ready for #as_json/#to_json/#serializable_hash.
    def initialize(resource, options = {})
      @resource = resource
      @adapter_opts, @serializer_opts =
        options.partition { |k, _| ADAPTER_OPTION_KEYS.include? k }.map { |h| Hash[h] }
    end

    delegate :serializable_hash, :as_json, :to_json, to: :adapter

    def serialization_scope=(scope)
      serializer_opts[:scope] = scope
    end

    def serialization_scope
      serializer_opts[:scope]
    end

    def serialization_scope_name=(scope_name)
      serializer_opts[:scope_name] = scope_name
    end

    def adapter
      @adapter ||= ActiveModel::Serializer::Adapter.create(serializer_instance, adapter_opts)
    end
    alias_method :adapter_instance, :adapter

    def serializer_instance
      @serializer_instance ||= serializer.new(resource, serializer_opts)
    end

    # Get serializer either explicitly :serializer or implicitly from resource
    # Remove :serializer key from serializer_opts
    # Replace :serializer key with :each_serializer if present
    def serializer
      @serializer ||=
        begin
          @serializer = serializer_opts.delete(:serializer)
          @serializer ||= ActiveModel::Serializer.serializer_for(resource)

          if serializer_opts.key?(:each_serializer)
            serializer_opts[:serializer] = serializer_opts.delete(:each_serializer)
          end
          @serializer
        end
    end
    alias_method :serializer_class, :serializer

    # True when no explicit adapter given, or explicit appear is truthy (non-nil)
    # False when explicit adapter is falsy (nil or false)
    def use_adapter?
      !(adapter_opts.key?(:adapter) && !adapter_opts[:adapter])
    end

    def serializer?
      use_adapter? && !!(serializer)
    end

    protected

    attr_reader :resource, :adapter_opts, :serializer_opts
  end
end

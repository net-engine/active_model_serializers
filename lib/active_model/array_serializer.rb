require "active_support/core_ext/class/attribute"

module ActiveModel
  # Active Model Array Serializer
  #
  # It serializes an Array, checking if each element that implements
  # the +active_model_serializer+ method.
  #
  # To disable serialization of root elements:
  #
  #     ActiveModel::ArraySerializer.root = false
  #
  class ArraySerializer
    attr_reader :object, :options

    class_attribute :root

    class << self
      class_attribute :serializer_class
      self.serializer_class = nil
    end

    def initialize(object, options={})
      @object, @options = object, options
    end

    def serializable_array
      @object.map do |item|
        if @options.has_key? :each_serializer
          serializer = @options[:each_serializer]
        elsif self.class.serializer_class?
          serializer = self.class.serializer_class
        elsif item.respond_to?(:active_model_serializer)
          serializer = item.active_model_serializer
        end

        if serializer
          serializer.new(item, @options)
        else
          item
        end
      end
    end

    def as_json(*args)
      @options[:hash] = hash = {}
      @options[:unique_values] = {}

      array = serializable_array.map do |item|
        if item.respond_to?(:serializable_hash)
          item.serializable_hash
        else
          item.as_json
        end
      end

      if root = @options[:root]
        hash.merge!(root => array)
      else
        array
      end
    end
  end

end

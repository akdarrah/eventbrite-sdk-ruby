module EventbriteSDK
  class Resource
    class Attributes
      attr_reader :attrs, :changes

      def self.build(attrs, schema)
        new({}, schema).tap do |instance|
          instance.assign_attributes(attrs)
        end
      end

      def initialize(hydrated_attrs = {}, schema = NullSchemaDefinition.new)
        @attrs = hydrated_attrs
        @schema = schema
        @changes = {}
      end

      def [](key)
        public_send(key)
      end

      def assign_attributes(new_attrs)
        new_attrs.each do |attribute_key, value|
          assign_value(attribute_key, value) if schema.writeable?(attribute_key)
        end

        nil
      end

      def changed?
        changes.any?
      end

      def to_h
        attrs.to_h
      end

      def inspect
        "#<#{self.class}: #{JSON.pretty_generate(@attrs.to_h)}>"
      end

      def reset!
        changes.each do |attribute_key, (old_value, _current_value)|
          bury(attribute_key, old_value)
        end

        @changes = {}

        true
      end

      # Provides changeset in a format that can be thrown at an endpoint
      #
      # prefix: This is needed due to inconsistencies in the EB API
      #         Sometimes there's a prefix, sometimes there's not,
      #         sometimes it's singular, sometimes it's plural.
      #         Once the API gets a bit more nomalized we can remove this
      #         alltogether and infer a prefix based
      #         on the class name of the resource
      def payload(prefix = nil)
        changes.each_with_object({}) do |(attribute_key, (_, value)), payload|
          key = if prefix
                  "#{prefix}.#{attribute_key}"
                else
                  attribute_key
                end

          payload[key] = value
        end
      end

      private

      attr_reader :schema

      def assign_value(attribute_key, value)
        dirty_check(attribute_key, value)
        bury(attribute_key, value)
      end

      def dirty_check(attribute_key, value)
        initial_value = attrs.dig(*attribute_key.split('.'))

        if initial_value != value
          changes[attribute_key] = [initial_value, value]
        end
      end

      def bury(attribute_key, value)
        keys = attribute_key.split '.'

        # Hand rolling #bury
        # hopefully we get it in the next release of Ruby
        keys.each_cons(2).reduce(attrs) do |prev_attrs, (key, _)|
          prev_attrs[key] ||= {}
        end[keys.last] = value
      end

      def method_missing(method_name, *_args, &_block)
        requested_key = method_name.to_s

        if attrs.has_key?(requested_key)
          handle_requested_attr(attrs[requested_key])
        else
          super
        end
      end

      def respond_to_missing?(method_name, _include_private = false)
        attrs.has_key?(method_name.to_s) || super
      end

      def handle_requested_attr(value)
        if value.is_a?(Hash)
          self.class.new(value)
        else
          value
        end
      end
    end
  end
end
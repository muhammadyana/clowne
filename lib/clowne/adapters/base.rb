# frozen_string_literal: true

require 'clowne/adapters/registry'

module Clowne
  module Adapters
    # ORM-independant adapter (just calls #dup).
    # Works with nullify/finalize.
    class Base
      class << self
        attr_reader :registry

        def inherited(subclass)
          # Duplicate registry
          subclass.registry = registry.dup
        end

        def resolver_for(type)
          registry.mapping[type] || raise("Uknown resolver #{type} for #{self}")
        end

        def register_resolver(type, resolver, after: nil, before: nil, prepend: nil)
          registry.mapping[type] = resolver

          if prepend
            registry.unshift type
          elsif after
            registry.insert_after after, type
          elsif before
            registry.insert_before before, type
          else
            registry.append type
          end
        end

        protected

        attr_writer :registry
      end

      self.registry = Registry.new

      def registry
        self.class.registry
      end

      # Using a plan make full duplicate of record
      # +source+:: Instance of cloned object (ex: User.new(posts: posts))
      # +plan+:: Array of Declarations
      # +params+:: Custom params hash
      def clone(source, plan, params: {})
        declarations = plan.declarations
        declarations.inject(init_record(dup_source(source))) do |record, (type, declaration)|
          resolver_for(type).call(source, record, declaration, params: params, adapter: self)
        end
      end

      def resolver_for(type)
        self.class.resolver_for(type)
      end

      def dup_source(source)
        source.dup
      end

      def init_record(record)
        # Override in custom adapters
        record
      end
    end
  end
end

require 'clowne/adapters/base/init_as'
require 'clowne/adapters/base/nullify'
require 'clowne/adapters/base/finalize'

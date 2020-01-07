require 'samvera/nesting_indexer/exceptions'
require 'forwardable'
require 'set'

module Samvera
  module NestingIndexer
    # Responsible for reindexing the document associated with the given PID and its descendant documents
    # @note There is cycle detection via the Samvera::NestingIndexer::Configuration#maximum_nesting_depth counter
    # @api private
    class RelationshipReindexer
      # @api private
      #
      # A convenience method that coordinate the relationship reindexing of the given id.
      #
      # @see #initialize
      # @return Samvera::NestingIndexer::RelationshipReindexer
      def self.call(**kwargs)
        new(**kwargs).call
      end

      # @param id [String]
      # @param maximum_nesting_depth [Integer] What is the maximum allowed depth of nesting
      # @param configuration [#adapter, #logger] The :adapter conforms to the Samvera::NestingIndexer::Adapters::AbstractAdapter interface
      #                                          and the :logger conforms to Logger
      # @param extent [String] - may be leveraged in adapter to limit the extent of the reindexing of children
      # @param queue [#shift, #push] queue
      def initialize(id:, maximum_nesting_depth:, configuration:, extent:, queue: [])
        @id = id.to_s
        @maximum_nesting_depth = maximum_nesting_depth.to_i
        @configuration = configuration
        @extent = extent
        @queue = queue
      end
      attr_reader :id, :maximum_nesting_depth

      # Perform a breadth-first tree traversal of the initial document and its descendants.
      # We index the document, then queue up each of its children. For each child, queue up the child's children.
      def call
        wrap_logging("nested indexing of ID=#{initial_index_document.id.inspect}") do
          enqueue(initial_index_document, maximum_nesting_depth)
          process_each_document
        end
        self
      end

      private

      attr_reader :queue, :configuration, :extent

      def process_each_document
        processing_document = dequeue
        while processing_document
          process_a_document(processing_document)
          adapter.each_child_document_of(document: processing_document, extent: extent) do |child|
            next if ActiveFedora::Base.find(id).class==Collection
          	enqueue(child, processing_document.maximum_nesting_depth - 1)
          end
          processing_document = dequeue
        end
      end

      def initial_index_document
        @initial_index_document ||= adapter.find_index_document_by(id: id)
      end

      extend Forwardable
      def_delegator :queue, :shift, :dequeue
      def_delegator :configuration, :adapter
      def_delegator :configuration, :logger

      require 'delegate'
      # A small object to help track time to live concerns
      class ProcessingDocument < SimpleDelegator
        def initialize(document, maximum_nesting_depth)
          @maximum_nesting_depth = maximum_nesting_depth
          super(document)
        end
        attr_reader :maximum_nesting_depth
      end
      private_constant :ProcessingDocument
      def enqueue(document, maximum_nesting_depth)
        queue.push(ProcessingDocument.new(document, maximum_nesting_depth))
      end

      # rubocop:disable Metrics/AbcSize
      def process_a_document(index_document)
        raise Exceptions::ExceededMaximumNestingDepthError, id: id if index_document.maximum_nesting_depth <= 0
        wrap_logging("indexing ID=#{index_document.id.inspect}") do
          preservation_document = adapter.find_preservation_document_by(id: index_document.id)
          nesting_document = build_nesting_document_for(preservation_document)
          guard_against_possiblity_of_self_ancestry(index_document: index_document, pathnames: nesting_document.pathnames)
          adapter.write_nesting_document_to_index_layer(nesting_document: nesting_document)
        end
      end
      # rubocop:enable Metrics/AbcSize

      def build_nesting_document_for(preservation_document)
        ParentAndPathAndAncestorsBuilder.new(preservation_document, adapter).nesting_document
      end

      def guard_against_possiblity_of_self_ancestry(index_document:, pathnames:)
        pathnames.each do |pathname|
          next unless pathname.include?("#{index_document.id}/")
          raise Exceptions::DocumentIsItsOwnAncestorError, id: index_document.id, pathnames: pathnames
        end
      end

      def wrap_logging(message_suffix)
        logger.debug("Starting #{message_suffix}")
        yield
        logger.debug("Ending #{message_suffix}")
      end

      # A small object that helps encapsulate the logic for building the hash of information regarding
      # the initialization of an Samvera::NestingIndexer::Documents::IndexDocument
      #
      # @see Samvera::NestingIndexer::Documents::IndexDocument for details on pathnames, ancestors, and parent_ids.
      class ParentAndPathAndAncestorsBuilder
        def initialize(preservation_document, adapter)
          @preservation_document = preservation_document
          @parent_ids = Set.new
          @pathnames = Set.new
          @ancestors = Set.new
          @adapter = adapter
          compile!
          @nesting_document = Documents::IndexDocument.new(id: @preservation_document.id, parent_ids: @parent_ids, pathnames: @pathnames, ancestors: @ancestors)
        end

        attr_reader :nesting_document

        private

        attr_reader :adapter, :extent

        def compile!
          @preservation_document.parent_ids.each do |parent_id|
            parent_index_document = adapter.find_index_document_by(id: parent_id)
            compile_one!(parent_index_document)
          end
          # Ensuring that an "orphan" has a path to get to it
          @pathnames << @preservation_document.id if @parent_ids.empty?
        end

        def compile_one!(parent_index_document)
          @parent_ids << parent_index_document.id
          parent_index_document.pathnames.each do |pathname|
            @pathnames << "#{pathname}#{Documents::ANCESTOR_AND_PATHNAME_DELIMITER}#{@preservation_document.id}"
            slugs = pathname.split(Documents::ANCESTOR_AND_PATHNAME_DELIMITER)
            slugs.each_index do |i|
              @ancestors << slugs[0..i].join(Documents::ANCESTOR_AND_PATHNAME_DELIMITER)
            end
          end
          @ancestors += parent_index_document.ancestors
        end
      end
      private_constant :ParentAndPathAndAncestorsBuilder
    end
  end
end
Samvera::NestingIndexer.private_constant :RelationshipReindexer

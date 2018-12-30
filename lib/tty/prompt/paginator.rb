# frozen_string_literal: true

module TTY
  class Prompt
    class Paginator
      DEFAULT_PAGE_SIZE = 6

      # The 0-based index of the first item on this page
      attr_reader :start_index

      # The 0-based index of the last item on this page
      attr_reader :end_index

      # Create a Paginator
      #
      # @api private
      def initialize(**options)
        @last_index  = Array(options[:default]).flatten.first || 0
        @per_page    = options[:per_page]
        @start_index = Array(options[:default]).flatten.first
      end

      # Check if page size is valid
      #
      # @raise [InvalidArgument]
      #
      # @api private
      def check_page_size!
        raise InvalidArgument, 'per_page must be > 0' if @per_page < 1
      end

      # Paginate collection given an active index
      #
      # @param [Array[Choice]] list
      #   a collection of choice items
      # @param [Integer] active
      #   current choice active index
      # @param [Integer] per_page
      #   number of choice items per page
      #
      # @return [Enumerable]
      #   the list between start and end index
      #
      # @api public
      def paginate(list, active, per_page = nil, &block)
        current_index = active - 1
        default_size = (list.size <= DEFAULT_PAGE_SIZE ? list.size : DEFAULT_PAGE_SIZE)
        @per_page = @per_page || per_page || default_size
        @start_index ||= current_index
        @end_index ||= @start_index + @per_page - 1

        check_page_size!

        # Don't paginate short lists
        if list.size <= @per_page
          @start_index = 0
          @end_index = list.size - 1
          if block
            return list.each_with_index(&block)
          else
            return list.each_with_index.to_enum
          end
        end

        if current_index > @last_index # going up
          if current_index > @end_index && current_index < list.size - 1
            @start_index += 1
          end
        elsif current_index < @last_index # going down
          if current_index < @start_index && current_index > 0
            @start_index -= 1
          end
        end

        # Cycle list
        if current_index.zero?
          @start_index = 0
        elsif current_index == list.size - 1
          @start_index = list.size - 1 - (@per_page - 1)
        end

        @end_index = @start_index + (@per_page - 1)
        @last_index = current_index

        sliced_list = list[@start_index..@end_index]
        page_range = (@start_index..@end_index)

        return sliced_list.zip(page_range).to_enum unless block_given?

        sliced_list.each_with_index do |item, index|
          block[item, @start_index + index]
        end
      end
    end # Paginator
  end # Prompt
end # TTY

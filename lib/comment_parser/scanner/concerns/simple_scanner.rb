module CommentParser::Scanner::Concerns::SimpleScanner
  include CommentParser::CodeObject::Comment::Type

  def self.included(k)
    k.class_eval do |klass|
      extend ClassMethods
    end
  end

  module ClassMethods
    include CommentParser::CodeObject::Comment::Type

    def define_rule(start: nil, stop: nil, type: ONE_LINER_COMMENT)
      @comment_regexp ||= []
      raise ArgumentError unless [type, start].all?

      definition = { start: build_regexp(start), type: type, stop: stop }

      if type == BLOCK_COMMENT
        definition[:stop] = build_regexp(stop, Regexp::MULTILINE)
      end
      @comment_regexp << definition
    end

    def define_ignore_patterns(*patterns)
      @ignore_patterns ||= []
      @ignore_patterns += patterns
    end

    def define_bracket(bracket, options = 0)
      start_regexp = build_regexp(bracket)
      stop_regexp = if bracket.is_a?(Regexp)
                 join_regexp(/(?<!\\)/, bracket)
               else
                 /(?<!\\)#{bracket}/
               end
      stop_regexp = Regexp.new(stop_regexp.source, options)
      append_bracket(start_regexp, stop_regexp)
    end

    def define_regexp_bracket
      append_bracket(%r!/(?=[^/])!, /(?<!\\)\//)
    end

    def define_default_bracket
      define_bracket('"', Regexp::MULTILINE)
      define_bracket("'", Regexp::MULTILINE)
    end

    def append_bracket(start, stop)
      @brackets ||= []
      @brackets << { start: start, stop: stop }
    end

    def define_complicate_condition(&proc_object)
      @complicate_conditions ||= []
      @complicate_conditions << proc_object
    end

    private

    def join_regexp(*regexp)
      # [review] - Should I ignore regexp options?
      Regexp.new(regexp.map { |v| v.source }.inject(:+))
    end

    def build_regexp(str_or_reg, type = 0)
      str_or_reg = str_or_reg.source if str_or_reg.respond_to?(:source)
      Regexp.new(str_or_reg, type)
    end
  end

  def self.attr_definition(*keys)
    keys.each do |key|
      define_method key do
        self.class.instance_variable_get("@#{key}") || []
      end
    end
  end
  attr_definition :brackets, :comment_regexp,
    :ignore_patterns, :complicate_conditions

  def scan
    until scanner.eos?
      case
      when scan_ignore_patterns
        next
      when scan_complicate_conditions
        next
      when scan_comment
        next
      when scan_bracket
        next
      when scanner.scan(CommentParser::Scanner::REGEXP[:BREAK])
        next
      when scanner.scan(/./)
        next
      else
        raise_report
      end
    end
  end

  private

  def scan_complicate_conditions
    complicate_conditions.each do |proc_object|
      return if self.instance_eval(&proc_object)
    end

    nil
  end

  def scan_bracket
    brackets.each do |definition|
      start = definition[:start]
      stop = definition[:stop]
      next unless scanner.scan(start)
      return scanner.scan(Regexp.new(/.*?/.source + stop.source, stop.options))
    end

    nil
  end

  def scan_ignore_patterns
    ignore_patterns.each do |pattern|
      return true if scanner.scan(pattern)
    end

    nil
  end

  def scan_comment
    comment_regexp.each do |definition|
      next unless scanner.scan(definition[:start])

      return case definition[:type]
      when ONE_LINER_COMMENT
        identify_single_line_comment
      when BLOCK_COMMENT
        identify_multi_line_comment(definition[:stop])
      else
        raise_report
      end
    end

    nil
  end

  def identify_single_line_comment
    line_number = current_line
    comment = scanner.scan(/^.*$/)
    add_comment(line_number, comment, type: ONE_LINER_COMMENT)
  end

  def identify_multi_line_comment(regexp)
    line_no = current_line
    stop_regexp = Regexp.new(/.*?/.source + regexp.source, regexp.options)
    comment_block = scanner.scan(stop_regexp)

    remove_tail_regexp = Regexp.new(regexp.source + /$/.source)
    comments = comment_block.sub(remove_tail_regexp, '').split("\n")
    comments.each_with_index do |comment, index|
      add_comment(line_no + index, comment, type: BLOCK_COMMENT)
    end
  end

  def scanner
    @scanner ||= build_scanner
  end
end

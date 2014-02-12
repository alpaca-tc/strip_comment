class CommentParser::Scanner::Python < CommentParser::Scanner
  include CommentParser::Scanner::Concerns::SimpleScanner

  filename /\.py$/
  filetype 'py'

  define_default_bracket
  define_rule start: '"""', stop: '"""', type: BLOCK_COMMENT
  define_rule start: '"""', stop: '"""', type: BLOCK_COMMENT
  define_rule start: '#'
end

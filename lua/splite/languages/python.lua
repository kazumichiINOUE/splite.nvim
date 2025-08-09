-- Python language configuration for splite.nvim

return {
  syntax = "python",
  background = "#011628",
  normal_fg = "#44475a",
  comment_fg = "#CBE0F0",
  comment_region = 'syntax region pythonDocstring start=\'"""lt\' end=\'"""\' contains=CommentHeader1,CommentHeader2,CommentHeader3,CommentHeader4,CommentBold,CommentItalic,CommentCodeInline,CommentCodePython,CommentCodeAlgorithm,CommentCodeBlock,CommentList,CommentListWithCode',
  normal_comment = 'syntax region pythonNormalDocstring start=\'"""\\(\\(lt\\)\\@!\\)\' end=\'"""\'',
  line_comment = 'syntax match pythonLineComment "#.*$"',
  delimiter = 'syntax match CommentDelimiter \'"""lt\' contained | syntax match CommentDelimiter \'"""\' contained',

  syntax_patterns = {
    header = {
      'syntax match CommentHeader1 /^\\s*#[^#].*$/ contained',
      'syntax match CommentHeader2 /^\\s*##[^#].*$/ contained',
      'syntax match CommentHeader3 /^\\s*###[^#].*$/ contained',
      'syntax match CommentHeader4 /^\\s*####.*$/ contained'
    },
    formatting = {
      'syntax match CommentBold /\\*\\*[^*]\\+\\*\\*/ contained',
      'syntax match CommentItalic /\\*[^*\\s][^*]*\\*/ contained',
      'syntax match CommentList /^\\s*[-*+]\\s\\+.*$/ contained',
      'syntax match CommentListWithCode /^\\s*[-*+]\\s\\+.*`[^`]\\+`.*$/ contained contains=CommentCodeInline'
    },
    code = {
      'syntax match CommentCodeInline /`[^`]\\+`/ contained',
      'syntax region CommentCodeBlock start=/```/ end=/```/ contained',
      'syntax region CommentCodePython start=/```python/ end=/```/ contained contains=PythonCodeKeyword,PythonCodeString',
      'syntax match PythonCodeKeyword /\\(def\\|class\\|import\\|from\\|if\\|else\\|elif\\|for\\|while\\|try\\|except\\|return\\|yield\\)/ contained',
      'syntax region PythonCodeString start=/"/ end=/"/ contained',
      'syntax region PythonCodeString start=/\'/ end=/\'/ contained',
      'syntax region CommentCodeAlgorithm start=/```algorithm/ end=/```/ contained contains=AlgoNumber,AlgoOperator',
      'syntax match AlgoNumber /^\\s*\\d\\+:/ contained',
      'syntax match AlgoOperator /\\(<-\\|!=\\|≠\\|←\\)/ contained'
    }
  },

  highlight_groups = {
    'highlight! link pythonDocstring Comment',
    'highlight pythonNormalDocstring guifg=#44475a gui=italic',
    'highlight pythonLineComment guifg=#44475a gui=italic',
    'highlight! CommentDelimiter guifg=#44475a gui=italic',
    'highlight CommentHeader1 guifg=#ff79c6 guibg=#011628 gui=bold,underline',
    'highlight CommentHeader2 guifg=#f7768e guibg=#011628 gui=bold',
    'highlight CommentHeader3 guifg=#e0af68 guibg=#011628 gui=bold',
    'highlight CommentHeader4 guifg=#9ece6a guibg=#011628',
    'highlight CommentBold guifg=#ff9500 guibg=#011628 gui=bold',
    'highlight CommentItalic guifg=#f8f8f2 guibg=#011628 gui=italic',
    'highlight CommentCodeInline guifg=#50fa7b guibg=#44475a gui=bold',
    'highlight CommentCodeBlock guifg=#50fa7b guibg=#2d3748 gui=bold',
    'highlight CommentCodePython guifg=#c0caf5 guibg=#1a1b26',
    'highlight PythonCodeKeyword guifg=#bb9af7 gui=bold',
    'highlight PythonCodeString guifg=#9ece6a',
    'highlight CommentCodeAlgorithm guifg=#c0caf5 guibg=#1a1b26',
    'highlight AlgoNumber guifg=#ff9e64 gui=bold',
    'highlight AlgoOperator guifg=#bb9af7 gui=bold',
    'highlight CommentList guifg=#8be9fd guibg=#011628',
    'highlight! link CommentListWithCode CommentList',
    'highlight! link Identifier Normal',
    'highlight! link Statement Normal',
    'highlight! link Type Normal',
    'highlight! link Special Normal',
    'highlight! link PreProc Normal',
    'highlight! link Constant Normal',
    'highlight! link Function Normal',
    'highlight! link Keyword Normal',
    'highlight! link String Normal',
    'highlight! link Number Normal',
    'highlight! link Boolean Normal',
    'highlight! link Operator Normal',
    'highlight! link Delimiter Normal',
    'highlight! link Variable Normal',
    'highlight! link @variable Normal',
    'highlight! link @variable.builtin Normal',
    'highlight! link @parameter Normal',
    'highlight! link @field Normal',
    'highlight! link @property Normal'
  }
}

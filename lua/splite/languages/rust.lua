-- Rust language configuration for splite.nvim

return {
  syntax = "rust",
  background = "#011628",
  normal_fg = "#44475a",
  comment_fg = "#CBE0F0",
  comment_region = 'syntax region rustComment start="/\\*lt" end="\\*/" ' ..
                   'contains=CommentHeader1,CommentHeader2,CommentHeader3,CommentHeader4,' ..
                   'CommentBold,CommentItalic,CommentCodeInline,CommentCodeRust,' ..
                   'CommentCodeAlgorithm,CommentCodeBlock,CommentList,CommentListWithCode',
  normal_comment = 'syntax region rustNormalComment start="/\\*\\(\\(lt\\)\\@!\\)" end="\\*/"',
  line_comment = 'syntax match rustLineComment "//.*$"',
  delimiter = 'syntax match CommentDelimiter "/\\*lt" contained | syntax match CommentDelimiter "\\*/" contained',

  syntax_patterns = {
    header = {
      'syntax match CommentHeader1 /^\\s*\\(\\*\\s*\\)\\?#[^#].*$/ contained',
      'syntax match CommentHeader2 /^\\s*\\(\\*\\s*\\)\\?##[^#].*$/ contained',
      'syntax match CommentHeader3 /^\\s*\\(\\*\\s*\\)\\?###[^#].*$/ contained',
      'syntax match CommentHeader4 /^\\s*\\(\\*\\s*\\)\\?####.*$/ contained'
    },
    formatting = {
      'syntax match CommentBold /\\*\\*[^*]\\+\\*\\*/ contained',
      'syntax match CommentItalic /\\*[^*\\s][^*]*\\*/ contained',
      'syntax match CommentList /^\\s*\\(\\*\\s*\\)\\?[-*+]\\s\\+.*$/ contained',
      'syntax match CommentListWithCode /^\\s*\\(\\*\\s*\\)\\?[-*+]\\s\\+.*`[^`]\\+`.*$/ contained contains=CommentCodeInline'
    },
    code = {
      'syntax match CommentCodeInline /`[^`]\\+`/ contained',
      'syntax region CommentCodeBlock start=/```/ end=/```/ contained',
      'syntax region CommentCodeRust start=/```rust/ end=/```/ contained contains=RustCodeKeyword,RustCodeFunction,RustCodeType,RustCodeString',
      'syntax match RustCodeKeyword /\\(fn\\|let\\|mut\\|Result\\|Ok\\|Err\\|Box\\|dyn\\)/ contained',
      'syntax match RustCodeFunction /\\w\\+\\ze(/ contained',
      'syntax match RustCodeType /\\<\\u\\w*/ contained',
      'syntax region RustCodeString start=/"/ end=/"/ contained',
      'syntax region CommentCodeAlgorithm start=/```algorithm/ end=/```/ contained contains=AlgoKeyword,AlgoNumber,AlgoProcedure,AlgoOperator',
      'syntax match AlgoKeyword /\\(procedure\\|while\\|do\\|case\\|of\\|end\\|Algorithm\\|Input\\|Output\\)/ contained',
      'syntax match AlgoNumber /^\\s*\\d\\+:/ contained',
      'syntax match AlgoProcedure /\\<\\u\\w*\\>/ contained',
      'syntax match AlgoOperator /\\(<-\\|!=\\|≠\\|←\\)/ contained'
    }
  },

  highlight_groups = {
    'highlight! link rustComment Comment',
    'highlight rustNormalComment guifg=#44475a gui=italic',
    'highlight rustLineComment guifg=#44475a gui=italic',
    'highlight! CommentDelimiter guifg=#44475a gui=italic',
    'highlight CommentHeader1 guifg=#ff79c6 guibg=#011628 gui=bold,underline',
    'highlight CommentHeader2 guifg=#f7768e guibg=#011628 gui=bold',
    'highlight CommentHeader3 guifg=#e0af68 guibg=#011628 gui=bold',
    'highlight CommentHeader4 guifg=#9ece6a guibg=#011628',
    'highlight CommentBold guifg=#ff9500 guibg=#011628 gui=bold',
    'highlight CommentItalic guifg=#f8f8f2 guibg=#011628 gui=italic',
    'highlight CommentCodeInline guifg=#50fa7b guibg=#44475a gui=bold',
    'highlight CommentCodeBlock guifg=#50fa7b guibg=#2d3748 gui=bold',
    'highlight CommentCodeRust guifg=#c0caf5 guibg=#1a1b26',
    'highlight RustCodeKeyword guifg=#bb9af7 gui=bold',
    'highlight RustCodeFunction guifg=#7aa2f7 gui=bold',
    'highlight RustCodeType guifg=#e0af68 gui=bold',
    'highlight RustCodeString guifg=#9ece6a',
    'highlight CommentCodeAlgorithm guifg=#c0caf5 guibg=#1a1b26',
    'highlight AlgoKeyword guifg=#f7768e gui=bold',
    'highlight AlgoNumber guifg=#ff9e64 gui=bold',
    'highlight AlgoProcedure guifg=#7aa2f7 gui=bold',
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
    'highlight! link @property Normal',
    'highlight! link @function Normal',
    'highlight! link @function.builtin Normal',
    'highlight! link @constructor Normal',
    'highlight! link @method Normal',
    'highlight! link DiagnosticUnnecessary Normal',
    'highlight! link DiagnosticUnderlineHint Normal',
    'highlight! link NvimTreeSpecialFile Normal',
    'highlight! link NvimTreeFolderName Normal',
    'highlight! link NvimTreeRootFolder Normal'
  }
}

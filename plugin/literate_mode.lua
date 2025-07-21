-- プラグイン重複読み込み防止
if vim.g.loaded_literate_mode then
  return
end
vim.g.loaded_literate_mode = 1

-- デフォルトキーマップの設定
vim.keymap.set('n', '<leader>lt', function()
  require('literate_mode').toggle()
end, { 
  desc = 'Toggle literate mode',
  noremap = true,
  silent = true 
})

-- コマンドの定義
vim.api.nvim_create_user_command('LiterateToggle', function()
  require('literate_mode').toggle()
end, { desc = 'Toggle literate mode' })
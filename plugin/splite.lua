-- プラグイン重複読み込み防止
if vim.g.loaded_splite then
  return
end
vim.g.loaded_splite = 1

-- デフォルトキーマップの設定
vim.keymap.set('n', '<leader>lt', function()
  require('splite').toggle()
end, { 
  desc = 'Toggle Splite mode',
  noremap = true,
  silent = true 
})

vim.keymap.set('n', '<leader>lv', function()
  require('splite').toggle_spread_view()
end, { 
  desc = 'Toggle spread view',
  noremap = true,
  silent = true 
})

vim.keymap.set('n', '<leader>ld', function()
  require('splite').toggle_todo_mode()
end, { 
  desc = 'Toggle todo mode',
  noremap = true,
  silent = true 
})

-- コマンドの定義
vim.api.nvim_create_user_command('SpliteToggle', function()
  require('splite').toggle()
end, { desc = 'Toggle Splite mode' })

vim.api.nvim_create_user_command('SpliteDebug', function()
  require('splite').debug_highlight()
end, { desc = 'Debug highlight under cursor' })

vim.api.nvim_create_user_command('SpliteSpread', function()
  require('splite').toggle_spread_view()
end, { desc = 'Toggle spread view' })

vim.api.nvim_create_user_command('SpliteTodo', function()
  require('splite').toggle_todo_mode()
end, { desc = 'Toggle todo mode' })
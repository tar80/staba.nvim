# :heavy_dollar_sign: Staba.nvim

![staba](https://github.com/user-attachments/assets/e69d6102-4280-486e-8369-1017ddc35e93)

Staba.nvim is a UI enhancement suite integrating Tabline, Statusline, and Statuscolumn.
It deviates from conventional display plugins by prioritizing functional
optimization and workflow streamlining over purely aesthetic "rich" displays.

Designed specifically for minimalist setups (`cmdheight=0`, `laststatus=2`),
it provides a focused set of providers and seamless integration with Noice.nvim.

> [!WARNING]
> Staba.nvim does not support any mouse operations

## Features

- [tabline components](#tabline)
- [statusline components](#statusline)
- [statuscolumn components](#statuscolumn)
- highlight LineNr/CursorLine according to mode
- [optimized fade for non-current windows](#enhanced-fade-control)
- [keymaps for buffer navigation](#keymaps)

## Requirements

- Neovim >= 0.10.0
- Nerd Fonts
- [Nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) (Optional)
- [Mini.icons](https://github.com/echasnovski/mini.icons) (Optional)
- [Noice.nvim](https://github.com/folke/noice.nvim) (Optional)

## Installation

- lazy.nvim

```lua
{
  'tar80/staba.nvim',
  opts = {
    -- Your configuration here
  },
}
```

## Configuration

<details>
<summary> Click to see default configuration </summary>

```lua
local ui = require('staba.icon.ui')

require('staba').setup({
    adjust_icon = false,  -- adds space to icons that are too narrow
    enable_fade = true,
    enable_underline = true, -- used as a horizontal separator for each buffer
    enable_sign_marks = true,
    enable_statuscolumn = true,
    enable_statusline = true,
    enable_tabline = true,
    mode_line = 'LineNr', -- "LineNr"|"CursorLineNr"|"CursorLine" or nil
    nav_keys = 'asdfghjklzxcvnmweryuiop', -- buffer navigation labels
    no_name = '[No Name]',
    ignore_filetypes = {
        fade = {},
        statuscolumn = { 'qf', 'help', 'terminal' },
        statusline = { 'terminal' }, -- recommended trouble, snacks_layout_box
        tabline = {},
    },
    statuscolumn = { 'sign', 'number', 'fold_ex' },
    statusline = {
        active = {
            left = { 'staba_logo', 'search_count', 'reg_recording' },
            middle = {},
            right = { '%<', 'diagnostics', ' ', 'filetype', 'encoding', ' ', 'position' },
            },
        inactive = {
            left = {},
            middle = { 'devicon', 'filename', '%*' },
            right = {}
        },
    },
    tabline = {
        left = { 'bufinfo', 'parent', 'shellslash', ' ' },
        right = {},
        view = { 'buffers', 'tabs' },
        bufinfo = {
            '%#StabaTabsReverse#', 'tab',
            '%#StabaBuffersReverse#', 'buffer',
            '%#StabaModified#', 'modified',
            '%#StabaSpecial#', 'unopened',
            '%* ',
        },
        active = { 'devicon', 'namestate' },
        tabs = {
            self.frame.tabs_left,
            '%#StabaTabs#',
            'nav_key',
            self.frame.tabs_left,
            'namestate'
        },
        buffers = {
            self.frame.buffers_left,
            '%#StabaBuffers#',
            'nav_key',
            self.frame.buffers_left,
            'namestate'
        },
    },
    frame = {
        tabs_left = '%#StabaTabsReverse#'..ui.frame.slant_d.left,
        tabs_right = '%#StabaTabsReverse#'..ui.frame.bar.right,
        buffers_left = '%#StabaBuffersReverse#'..ui.frame.slant_d.left,
        buffers_right = '%#StabaBuffersReverse#'..ui.frame.bar.right,
        statusline_left = '%#StabaStatusReverse#'..ui.frame.slant_u.left,
        statusline_right = '%#StabaStatusReverse#'..ui.frame.slant_u.right
    },
    sep = {
        normal_left = '%#TabLineFill#'..ui.sep.arrow.left..'%* '
        normal_right = '%#TabLineFill#'..ui.sep.arrow.right..'%* '
    },
    icons = {
        logo = { '', 'WarningMsg' },
        bar = '│',
        bufinfo = { tab = 'ᵀ', buffer = 'ᴮ', modified = 'ᴹ', unopened = 'ᵁ' },
        fold = { open = '󰍝', close = '󰍟', blank = ' ' }, -- "blank" is provided for adjusting ambiwidth.
        fileformat = {
            dos = { '', 'Changed' },
            mac = { '', 'Removed' },
            unix = { '', 'Added'  },
        },
        severity = {
            Error = { '', 'DiagnosticSignError' },
            Warn = { '', 'DiagnosticSignWarn'  },
            Hint = { '', 'DiagnosticSignHint'  },
            Info = { '', 'DiagnosticSignInfo'  },
        },
        status = {
            lock = { '󰍁', 'StabaReadonly' },
            unlock = '  ',
            modify = { '󰐖', 'StabaModified' },
            nomodify = '  ',
            unopen = { '󰌖', 'StabaSpecial' },
            open = '  ',
            rec1 = '󰻿',
            rec2 = '󰕧',
            copilot = { '', 'StabaCopilot' },
            uncopilot = { '', 'Comment' },
        },
    },
})
```

</details>

> [!TIP]
> Contains unused settings such as `sep`, `icons.status`

## Tabline

Staba's Tabline introduces a predictable mental model. Unlike standard implementations where buffers shift positions, Staba maintains a constant arrangement:

1. The **leftmost** slot is always the **Current Buffer**.
2. The **second** slot is always the **Alternate Buffer**.
3. Remaining space is filled with other buffers and tab pages.

The header indicators represent (from left to right): Total Tabpages, Total Buffers, Modified Buffers, and Hidden Arglists.

![tabline_details](https://github.com/user-attachments/assets/d412edd7-7a9c-4269-81b1-f995f3954aca)

> [!IMPORTANT]
> Access to the tabs is facilitated through a dedicated <Plug> keymaps.

## Statusline

This element displays file information and provides a provider related to Noice.nvim.
You can register your own functions as providers, so please create what you need.
As an example, I will mention a function for displaying repositories using **Gitsigns.nvim**.

![gitsigns](https://github.com/user-attachments/assets/4baebc16-6ae8-43f5-99f6-2f9b5bc6ba65)

<details>
<summary> Click to see component function for gitsigns </summary>

```lua
local git_signs = function()
  local status = vim.b.gitsigns_status_dict
  if not status then
    return ''
  end
  local root = status.root:gsub('^(.+[/\\])', '')
  local head = status.head
  local stage = ('%s+%s%s~%s%s!%s%s '):format(
    '%#Changed#', status.changed,
    '%#Added#', status.added,
    '%#Removed#', status.removed,
    '%*'
  )
  return ('%s %s %s '):format(root, head, stage)
end

-- Then add it to your component settings.
require('staba').setup({
    opts = {
        statusline = {
            active = {
                left = { git_signs },
                middle = {...},
                right = {...},
            },
            inactive = {...},
        },
    }
})
```

</details>

## Statuscolumn

This element allows for the display of fold markers, and line highlighting based
on vi-mode. The fold marker display was created with reference to Snacks.nvim.
While that implementation is highly functional and powerful, Staba.nvim is designed to be simpler.

- **Mode-aware Highlighting**: Line numbers or cursor lines change color based on the current vi-mode.
- **Mark Signs**: Visualizes buffer marks in the signcolumn. Use the <Plug> maps to toggle or delete marks on the fly.

[fold](https://github.com/user-attachments/assets/3cfb2dee-ac2f-4664-8479-0156aa3f8192)

Displays the mark status of the buffer in the signcolumn. Register, delete, and
toggle operations using `<Plug>(staba-mark-xxx)` keys.

[marks](https://github.com/user-attachments/assets/8dd5c569-17bc-458d-a6db-73ef8b7c28e1)

## Enhanced Fade Control

The default non-current buffer fade function is useful, but it has some problems:

- `NormalNC` highlight can affect `FloatBorder` highlight on the plugin side
- When a popup is activated, the original window is also faded as well

Staba.nvim solves these problems.

![fade](https://github.com/user-attachments/assets/2e293c4c-a79f-42ee-93a5-d166d0ba783e)

> [!NOTE]
>
> - For full functionality you need to omit `NormalNC` and `StatusLineNC` from your colorscheme.
> - If the fade function has been independently adjusted on other plugins, it may not function correctly.

## Underlines as Window Separators

> [!CAUTION]
> Underlines can be used as window separators, but may not work correctly on some
> terminals. In such cases, the display can be adjusted by setting `_`(underscore)
> to `stl` and `stlnc` in `fillchars`. However, if guisp does not work,
> there does not seem to be a workaround.

![underline](https://github.com/user-attachments/assets/fb1d3d75-0668-4388-b362-6d2c685d9c23)

## Keymaps

### Buffer Operations

- **<Plug>(staba-pick)**: Select a buffer by label.
  - `Key`: Open in current window.
  - `Shift + Key`: Open in a horizontal split.
  - `Ctrl + Key`: Open in a vertical split.
- **<Plug>(staba-delete-current)**: Unload/delete the current buffer.
- **<Plug>(staba-delete-select)**: Delete a specific buffer by label.
- **<Plug>(staba-cleanup)**: Wipe all unchanged/unlisted buffers to keep your environment clean.

### Mark Operations

- **<Plug>(staba-mark-operator)**: Works like the native m key but updates UI signs immediately.
- **<Plug>(staba-mark-toggle)**: Toggle mark m on the current line.
- **<Plug>(staba-mark-delete)**: Clear mark on the current line.
- **<Plug>(staba-mark-delete-all)**: Wipe all alphabetical marks from the buffer.

### Example Mapping

```lua
vim.keymap.set('n', 'gb', '<Plug>(staba-pick)')
vim.keymap.set('n', '<C-w>1', '<Plug>(staba-cleanup)')
vim.keymap.set('n', '<C-w>q', '<Plug>(staba-delete-select)')
-- "q" must be removed from the `nav_key` value
vim.keymap.set('n', '<C-w>qq', '<Plug>(staba-delete-current)')

vim.keymap.set('n', 'm', '<Plug>(staba-mark-operator)', {})
vim.keymap.set('n', 'mm', '<Plug>(staba-mark-toggle)', {})
vim.keymap.set('n', 'md', '<Plug>(staba-mark-delete)', {})
vim.keymap.set('n', 'mD', '<Plug>(staba-mark-delete-all)', {})
```

> [!TIP]
> By default, `<Plug>(staba-pick)` splits the window above for horizontal splits
> and to the left for vertical splits. To temporarily change this behavior,  
> configure it as follows:

```lua
vim.keymap.set('n', 'gB' function()
    vim.go.splitbelow = true
    vim.go.splitright = true
    vim.api.nvim_input('<Plug>(staba-pick)')
    vim.defer_fn(function()
        vim.go.splitbelow = false
        vim.go.splitright = false
    end, 1000)
end)
```

## Acknowledgments

Staba.nvim is inspired by and built upon concepts from:

- [Snacks.nvim](https://github.com/folke/snacks.nvim)
- [Staline.nvim](https://github.com/tamton-aquib/staline.nvim)

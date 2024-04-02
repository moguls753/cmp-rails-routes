# cmp-rails-routes

nvim-cmp source for Rails route helpers.

![Demo](https://i.imgur.com/KEGeEBO.gif)

## Installation
### lazy.nvim
``` lua
{
  'moguls753/cmp-rails-routes',
  dependencies = {
    'nvim-lua/plenary.nvim'
  }
}
```

### packer.nvim
``` lua
use {
  'moguls753/cmp-rails-routes',
  requires = {
    'nvim-lua/plenary.nvim'
  }
}
```

## Setup
Put ```name = 'rails-route-helpers'``` in your nvim-cmp sources. Like this:
``` lua
require'cmp'.setup({
  { name = 'rails-route-helpers' }
})
```

; extends
; Extra markdown textobjects on top of nvim-treesitter-textobjects' defaults.
; Mapped in pwnvim/plugins/treesitter.lua (al/il/aL/aS).

(list_item) @item.outer

(list_item
  (paragraph
    (inline) @item.inner))

(list) @list.outer

(section) @section.outer

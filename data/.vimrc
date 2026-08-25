au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Vim probes the terminal for its background colour (OSC 11) and falls back to
" its *light* palette when it gets no answer -- which is the common case in a
" container. On a dark terminal that palette renders comments as dark blue
" (ESC[34m), the near-unreadable "low-contrast purple" this line exists to fix.
" Stating the background explicitly is the entire fix.
"
" Deliberately NOT set here: a bundled colorscheme plus 'termguicolors'. That
" combination makes vim emit 24-bit RGB for every cell and paint the scheme's
" own muted palette over the terminal's tuned one -- habamax's Normal is
" #bcbcbc on #1c1c1c, so normal text stops being the terminal's white and the
" whole window reads as washed out. It looked like a container-specific colour
" bug; it was just the colorscheme. Leave vim on the terminal palette.
set background=dark
syntax on

set ff=unix             " Use Unix (LF) line endings
set showcmd             " Show (partial) command in status line.
set showmatch           " Show matching brackets.
set ignorecase          " Do case insensitive matching
set smartcase           " Do smart case matching
set incsearch           " Incremental search
set autowrite           " Automatically save before commands like :next and :make
set hidden              " Hide buffers when they are abandoned
set mouse=a             " Enable mouse usage (all modes)

set number
set cursorline
set cursorcolumn
set shiftwidth=4
set tabstop=4
set expandtab
set scrolloff=10
set showmode
set hlsearch

set autoindent
set smartindent
set cindent
filetype indent on

augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END

" Set the menu & message to English
set langmenu=en_US
let $LANG='en_US'
source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim
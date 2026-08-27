" ---------------------------------------------------------------------------
" Encoding. Must be the first thing in this file: 'encoding' decides how every
" buffer loaded after it is interpreted.
"
" Vim picks 'encoding' from the locale (nl_langinfo(CODESET)) at startup. A
" container with no generated UTF-8 locale reports ANSI_X3.4-1968, so vim
" settles on latin1 and every multi-byte character typed at the terminal --
" Chinese, an em dash, an emoji -- arrives as one latin1 glyph per UTF-8 byte.
" That is the "strange chars instead of Chinese" mojibake. The image now
" generates en_US.UTF-8 (see data/install-common.sh), but pinning UTF-8 here
" keeps vim correct under any runtime that starts it with a broken or unset
" LANG -- Apptainer, `docker run --entrypoint bash`, a bare ssh session.
set encoding=utf-8
scriptencoding utf-8
set termencoding=utf-8  " Bytes exchanged with the terminal are UTF-8
set fileencoding=utf-8  " Write new files as UTF-8
" Read order: first entry that decodes the whole file wins, so utf-8 comes
" before the legacy CJK codepages and latin1 sits last as the never-fails
" fallback (it accepts any byte, so nothing after it would ever be tried).
set fileencodings=ucs-bom,utf-8,gb18030,big5,euc-jp,euc-kr,latin1
set ambiwidth=single    " Ambiguous-width cells: match the terminal's own choice
" ---------------------------------------------------------------------------

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

" Set the menu & message to English.
"
" The `.UTF-8` suffix is load-bearing: $LANG is inherited by everything vim
" spawns (`:!`, `:make`, `:terminal`), and a bare `en_US` names a locale that
" does not exist, which drops those children back to the C locale's ASCII
" charmap and re-creates the mojibake this file just fixed.
set langmenu=en_US
let $LANG='en_US.UTF-8'
source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim

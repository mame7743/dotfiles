" =============================================================================
" .vimrc
" =============================================================================

" --- Basics ------------------------------------------------------------------
set nocompatible
filetype plugin indent on
syntax enable

set encoding=utf-8
set fileencoding=utf-8
set termencoding=utf-8

" --- UI ----------------------------------------------------------------------
set number
set relativenumber
set cursorline
set signcolumn=yes
set scrolloff=8
set colorcolumn=100
set laststatus=2
set showcmd
set wildmenu
set wildmode=longest:full,full

" --- Editing -----------------------------------------------------------------
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
set smartindent

set backspace=indent,eol,start
set wrap
set linebreak

" --- Search ------------------------------------------------------------------
set hlsearch
set incsearch
set ignorecase
set smartcase

" Clear search highlight with Escape
nnoremap <Esc><Esc> :nohlsearch<CR>

" --- Files -------------------------------------------------------------------
set hidden
set noswapfile
set nobackup
set undofile
set undodir=$HOME/.vim/undo

" --- Keymaps -----------------------------------------------------------------
let mapleader = " "

nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>e :e $MYVIMRC<CR>

" Move between splits
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" --- Local overrides (not tracked by git) ------------------------------------
if filereadable(expand('~/.vimrc.local'))
  source ~/.vimrc.local
endif

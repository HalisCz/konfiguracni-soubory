"pluginy
	"vundle
		set rtp+=~/.vim/bundle/Vundle.vim
		call vundle#begin()
		filetype off
		"managed plugins
			Plugin 'gmarik/Vundle.vim'
			Plugin 'lokaltog/powerline'
			Plugin 'tpope/vim-fugitive'
			Plugin 'klen/python-mode'
			Plugin 'tobyS/skeletons.vim'
			Plugin 'SirVer/ultisnips'
			Plugin 'honza/vim-snippets'
			Plugin 'altercation/vim-colors-solarized'
			Plugin 'godlygeek/tabular'
			Plugin 'scrooloose/nerdcommenter'
		call vundle#end()
		filetype plugin indent on
		"Python mode
			let g:pymode_options = 0 "nehrabej mi do nastavení, ale aktivuj v nich tyto
			setlocal commentstring=#%s
			setlocal define=^\s*\\(def\\\\|class\\)

	" Powerline setup
		set rtp+=/usr/lib64/python3.3/site-packages/powerline/bindings/vim
		set guifont=Terminess\ Powerline\ 9
		set laststatus=2
		set t_Co=256

"generic
	set nocompatible				"není to vi ale vim
	set visualbell					"vizuální zvonek
	set title
	set titlestring=VIM\ %f%y%m%r	"titulek
	set mouse=a							"myš v konzole
	set confirm							"pokud jsem nepoužil ! a měl jsem, tak se mě zeptá co dělat
	set nojoinspaces				"při spojování řádků nedává dvě mezery
	set clipboard=unnamed		"Vše, co se ukládá do "unnamed" registru, se bude ukládat zároveň i do clipboardu.
	set autochdir				"automaticky přejdi do adresáře s otevíraným souborem
	autocmd! bufwritepost .vimrc source %		"při uložení automaticky načte .vimrc

"ovládání
	set backspace=indent,eol,start "Backspace maže odsazení, konce řádků,...
	let mapleader = ",,"
	let maplocalleader = ",,"

"zvýrazňování
	syntax on
	set showmatch						"zvýraznění páru závorek

"formáty
	set fileencodings=utf-8,iso8859-2,cp1250
	set fileformats=unix,dos

"statusline
	set showcmd							"ukazuje příkazy na posledním řádku
	set laststatus=2				"znamená, že chceme, aby byl stavový řádek zapnutý vždy

"pozice
	set number							"ukazuje čísla řádků
	set ruler								"ukazuj pozici kurzoru

"zobrazení
	set scrolloff=3					"minimální počet viditelných řádků při rolování
	set sidescroll=3				"totéž při posun za strany
	set wrap								"zobrazuje řádky zalomeně
	set linebreak						"zlom jen ve slově 
	set autoindent					"jen zachovává odsazení
	set smartindent					"zachovává odsazení ale inteligentně ho umí zvětšit/zmenšit
	filetype plugin indent on	"odsazovaní podle filetype

"vyhledávání
	set wrapscan						"po dosažení konce souboru se hledá znovu od začátku
	set hlsearch						"zvýraznění hledaného textu
	set ignorecase					"při hledání nerozlišuje velká a malá písmena
	set smartcase						"ignorecase platí pouze tehdy pokud v~hledaném výrazu jsou jen malá písmena
	set incsearch						"ukazuje mi co hledám ještě předtím než dám Enter

"slovníky
	set helplang=cs					"jazyk nápovědy
	map <Leader>s :set spell spelllang=cs,en<Return>
	map <Leader>S :set nospell<Return>

"doplňování
	set wildchar=<Tab>
	set wildmenu						"v :příkazovém řádku zobrazí menu pro výběr
	set wildmode=list:longest,list:full	"chování TAB v~příkazovém řádku
	set wildignore=*~,*.o,*.aux	"Ignoruje při doplňování tabulátorem

"sudo trick
	cmap w!! w !sudo tee > /dev/null %

"odsazování
	set tabstop=4						"odsazení tabulátoru
	set shiftwidth=4				"šířka odsazení při >>
	set noexpandtab					"Use tabs, not spaces
	set shiftround					"Zaokrouhluj počet mezer při odsazování (>> C-T << C-D) na násobek shiftwidth.
	vnoremap < <gv	"během odsazování zachová výběr
	vnoremap > >gv

"historie a zálohování
	set history=200
	set backup
	set backupdir=~/.vim/backup

"folding
	set foldcolumn=4
	set foldmethod=indent
	set foldmarker=##,::

"filetype specific options
	"source ~/.vim/skeletons.vim
	"autocmd BufRead,BufNewFile *.html,*.xhtml,*.php source ~/.vim/html.vim
	"autocmd BufRead,BufNewFile *.html,*.xhtml,*.php source ~/.vim/html.menu
	"au BufNewFile *.php,*.html,*.xhtml 0r ~/.vim/sablony/xhtml.html
	"autocmd BufRead,BufNewFile *.html,*.xhtml,*.php set filetype=xhtml
	"au BufNewFile *.fold 0r ~/.vim/sablony/osnova.fold
	"au BufNewFile *.fold set filetype=conf
	"au BufNewFile *.tex 0r ~/.vim/sablony/latex.tex
	"au BufRead,BufNewFile *.tex set filetype=tex
	"au BufNewFile *.pl 0r ~/.vim/sablony/perl.pl
	"au BufNewFile *.c 0r ~/.vim/sablony/program.c

	"au BufNewFile,BufRead *.t2t set ft=txt2tags
	"au BufNewFile *.t2t 0r ~/.vim/sablony/txt2tags.t2t
	"au BufNewFile,BufRead *.asm set ft=asm8051
	"au BufNewFile,BufRead *.inc set ft=asm8051

	"au BufRead *.PAS set ft=pascal
	"au BufRead *.lpr set ft=pascal


"Vzhled
	"colorscheme darkblue
"	let g:solarized_termcolors=256
	set background=dark
	colorscheme solarized

"páry
	imap <> <><Esc>i
	imap () ()<Esc>i
	imap [] []<Esc>i
	imap {} {}<Esc>i
	imap $$ $$<Esc>i
	imap "" ""<Esc>i
	imap '' ''<Esc>i
	imap ** **<Esc>i

"spustí shell z označeným příkazem
	"příkaz shell pod kurzorem
		map <Leader>e :!<C-R><C-A>& <Return>
	"označený příkaz
		vmap <Leader>e y:!<C-R>"& <Return>
	"celý řádek zadá jako příkaz shell
		map <Leader>E ^v$h<Leader>e
		imap <Leader>E <Esc><Leader>E
"řetězec pod kurzorem vloží jak URL do prohlížeče
	map <Leader>w :!firefox <C-R><C-A> & <Return>

"Formátování
	"formátovat odstavec
		map <Leader><Return> gwap
		imap <Leader><Return> <Esc>gwapa
	map <Leader>g<Return> gogqG

set ww=b,s,<,>,[,],~ ",h,l "chování na přechodu dvou řádků

"""""""""""""""""""""" Enhanced commentify plugin
" let g:EnhCommentifyTraditionalMode = 'no'
" let g:EnhCommentifyUserMode = 'yes'
" let g:EnhCommentifyAlignRight = 'yes'
" let g:EnhCommentifyMultiPartBlocks = 'yes'
" let g:EnhCommentifyUseSyntax = 'yes'

""""""""""""""""""""""""""""""""
"vim:nospell:

"pluginy
	"vundle
		set rtp+=~/.vim/bundle/Vundle.vim
		call vundle#begin()
		filetype off
		"managed plugins
			Plugin 'airblade/vim-gitgutter'
			"Plugin 'altercation/vim-colors-solarized'
			Plugin 'lifepillar/vim-solarized8'
			Plugin 'ctrlpvim/ctrlp.vim'
			Plugin 'fmoralesc/vim-pinpoint'
			Plugin 'gmarik/Vundle.vim'
			Plugin 'godlygeek/tabular'
			Plugin 'honza/vim-snippets'
			Plugin 'junegunn/fzf'
			Plugin 'nathanaelkane/vim-indent-guides'
			Plugin 'python-mode/python-mode'
			Plugin 'scrooloose/nerdcommenter'
			Plugin 'scrooloose/nerdtree'
			Plugin 'sheerun/vim-polyglot'
			Plugin 'tobyS/skeletons.vim'
			Plugin 'tpope/vim-fugitive'
			Plugin 'tpope/vim-surround'
			Plugin 'vim-airline/vim-airline'
			Plugin 'vim-airline/vim-airline-themes'
			Plugin 'w0rp/ale'
		call vundle#end()
		filetype plugin indent on
		"Python mode
			let g:pymode_python = 'python3' "use python3 syntax check by default
			setlocal commentstring=#%s
			setlocal define=^\s*\\(def\\\\|class\\)
		" vim-airline setup
			let g:airline_theme='solarized'
			"let g:airline#extensions#tabline#enabled = 1 " show buffers line
			let g:airline_powerline_fonts = 1
			if !exists('g:airline_symbols')
				let g:airline_symbols = {}
			endif
			" unicode symbols
			let g:airline_left_sep = '»'
			let g:airline_left_sep = '▶'
			let g:airline_right_sep = '«'
			let g:airline_right_sep = '◀'
			let g:airline_symbols.linenr = '␊'
			let g:airline_symbols.linenr = '␤'
			let g:airline_symbols.linenr = '¶'
			let g:airline_symbols.branch = '⎇'
			let g:airline_symbols.paste = 'ρ'
			let g:airline_symbols.paste = 'Þ'
			let g:airline_symbols.paste = '∥'
			let g:airline_symbols.whitespace = 'Ξ'
			" airline symbols
			let g:airline_left_sep = ''
			let g:airline_left_alt_sep = ''
			let g:airline_right_sep = ''
			let g:airline_right_alt_sep = ''
			let g:airline_symbols.branch = ''
			let g:airline_symbols.readonly = ''
			let g:airline_symbols.linenr = ''
		" w0rp/ale
			let g:ale_fixers = {
			\   '*': ['remove_trailing_lines', 'trim_whitespace'],
			\	'terraform': ['terraform'],
			\   'javascript': ['eslint'],
			\}

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
	let mapleader = ","
	let maplocalleader = ","

"zvýrazňování
	syntax on
	set showmatch						"zvýraznění páru závorek

"formáty
	set fileencodings=utf-8,iso8859-2,cp1250
	set fileformats=unix,dos
	set nrformats-=octal		"čísla začínající nulou neber jako osmičkovou soustavu

"statusline
	set showcmd							"ukazuje příkazy na posledním řádku
	set laststatus=2				"znamená, že chceme, aby byl stavový řádek zapnutý vždy

"pozice
	set number							"ukazuje čísla řádků
	set ruler								"ukazuj pozici kurzoru

"zobrazení
	set scrolloff=3					"minimální počet viditelných řádků při rolování
	set sidescrolloff=3				"totéž při posun za strany
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
	if exists('+termguicolors')
		let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
		let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
		set termguicolors
	endif
	set background=dark
	colorscheme solarized8
	let g:solarized_term_italics=1

"vim-indent-guides
	let g:indent_guides_enable_on_vim_startup = 1
	let g:indent_guides_auto_colors = 0
	highlight IndentGuidesOdd  ctermbg=black
	highlight IndentGuidesEven ctermbg=darkgrey

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

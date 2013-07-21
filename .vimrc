" generic
set nocompatible	"není to vi ale vim

" zvýrazňování
syntax on
set showmatch "zvýraznění páru závorek

" formáty
set fileencodings=utf-8,iso8859-2,cp1250
set fileformats=unix,dos

" statusline
set showcmd		"ukazuje příkazy na posledním řádku
set showmode		"ukazuj režim INZERT, REPLACE ....
set laststatus=2	"znamená, že chceme, aby byl stavový řádek zapnutý vždy

" pozice
set number		"ukazuje čísla řádků
set ruler		"ukazuj pozici kurzoru

" zobrazení
set scrolloff=3		"minimální počet viditelných řádků při rolování
set sidescroll=3	"totéž při posun za stránky

" vyhledávání
set wrapscan 		"po dosažení konce souboru se hledá znovu od začátku
set hlsearch		"zvýraznění hledaného textu
set ignorecase		"při hledání nerozlišuje velká a malá písmena
set smartcase		"ignorecase platí pouze tehdy pokud v~hledaném výrazu jsou jen malá písmena
set incsearch		"ukazuje mi co hledám ještě předtím než dám Enter

" slovník
set helplang=cs

" doplňování
set wildmenu		"v :příkazovém řádku zobrazí menu pro výběr
set wildmode=list:longest,list:full	"chování TAB v~příkazovém řádku
set wildignore=*~,*.o,*.log,*.aux	"Ignoruje při doplňování tabulátorem

set nojoinspaces " při spojování řádků nedává dvě mezery

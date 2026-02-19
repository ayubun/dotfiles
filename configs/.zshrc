# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  # starship
  git
  rust
  yarn
  bun
  pip
  # uv
  tldr
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


# Put prompt at the bottom of the terminal
# printf '\n%.0s' {1..100}
# To customize prompt, run p10k configure or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# starship
# eval "$(starship init zsh)"

# specifying term to fix ghostty incompatibilities
export TERM=xterm-256color

export VISUAL=nvim
export EDITOR=nvim
# https://github.com/sharkdp/vivid?tab=readme-ov-file#theme-preview
# to preview all themes:
# for theme in $(vivid themes); do
#   echo "Theme: $theme"
#   export LS_COLORS=$(vivid generate $theme)
#   ll
#   echo
# done
# tokyonight-moon:
# export LS_COLORS="*~=0;38;2;68;74;115:bd=1;38;2;255;117;127;48;2;52;35;53:ca=0;48;2;45;63;118:cd=1;38;2;255;199;119;48;2;48;42;53:di=1;38;2;130;170;255:do=1;38;2;252;167;234;48;2;42;34;56:ex=1;38;2;195;232;141:fi=0:ln=3;38;2;137;221;255:mh=0:mi=0;38;2;197;59;83:no=0;38;2;99;109;166:or=0;38;2;34;36;54;48;2;197;59;83:ow=1;38;2;130;170;255;48;2;45;63;118:pi=1;38;2;255;150;108;48;2;50;37;52:rs=0;38;2;99;109;166:sg=0;48;2;45;63;118:so=1;38;2;79;214;190;48;2;33;48;60:st=0;48;2;45;63;118:su=0;48;2;45;63;118:tw=1;38;2;34;36;54;48;2;130;170;255:*.1=0;38;2;200;211;245:*.a=0;38;2;79;214;190:*.c=0;38;2;255;199;119:*.d=0;38;2;255;199;119:*.h=0;38;2;255;199;119:*.m=0;38;2;255;199;119:*.o=0;38;2;68;74;115:*.p=0;38;2;255;199;119:*.r=0;38;2;255;199;119:*.t=0;38;2;255;199;119:*.v=0;38;2;255;199;119:*.z=1;38;2;255;117;127:*.7z=1;38;2;255;117;127:*.ai=1;38;2;192;153;255:*.as=0;38;2;255;199;119:*.bc=0;38;2;68;74;115:*.bz=1;38;2;255;117;127:*.cc=0;38;2;255;199;119:*.cp=0;38;2;255;199;119:*.cr=0;38;2;255;199;119:*.cs=0;38;2;255;199;119:*.db=1;38;2;255;117;127:*.di=0;38;2;255;199;119:*.el=0;38;2;255;199;119:*.ex=0;38;2;255;199;119:*.fs=0;38;2;255;199;119:*.go=0;38;2;255;199;119:*.gv=0;38;2;255;199;119:*.gz=1;38;2;255;117;127:*.ha=0;38;2;255;199;119:*.hh=0;38;2;255;199;119:*.hi=0;38;2;68;74;115:*.hs=0;38;2;255;199;119:*.jl=0;38;2;255;199;119:*.js=0;38;2;255;199;119:*.ko=0;38;2;79;214;190:*.kt=0;38;2;255;199;119:*.la=0;38;2;68;74;115:*.ll=0;38;2;255;199;119:*.lo=0;38;2;68;74;115:*.ma=1;38;2;192;153;255:*.mb=1;38;2;192;153;255:*.md=0;38;2;200;211;245:*.mk=0;38;2;13;185;215:*.ml=0;38;2;255;199;119:*.mn=0;38;2;255;199;119:*.nb=0;38;2;255;199;119:*.nu=0;38;2;255;199;119:*.pl=0;38;2;255;199;119:*.pm=0;38;2;255;199;119:*.pp=0;38;2;255;199;119:*.ps=1;38;2;252;167;234:*.py=0;38;2;255;199;119:*.rb=0;38;2;255;199;119:*.rm=1;38;2;79;214;190:*.rs=0;38;2;255;199;119:*.sh=0;38;2;255;199;119:*.so=0;38;2;79;214;190:*.td=0;38;2;255;199;119:*.ts=0;38;2;255;199;119:*.ui=0;38;2;255;150;108:*.vb=0;38;2;255;199;119:*.wv=1;38;2;101;188;255:*.xz=1;38;2;255;117;127:*FAQ=1;38;2;137;221;255:*.3ds=1;38;2;192;153;255:*.3fr=1;38;2;192;153;255:*.3mf=1;38;2;192;153;255:*.adb=0;38;2;255;199;119:*.ads=0;38;2;255;199;119:*.aif=1;38;2;101;188;255:*.amf=1;38;2;192;153;255:*.ape=1;38;2;101;188;255:*.apk=1;38;2;255;117;127:*.ari=1;38;2;192;153;255:*.arj=1;38;2;255;117;127:*.arw=1;38;2;192;153;255:*.asa=0;38;2;255;199;119:*.asm=0;38;2;255;199;119:*.aux=0;38;2;68;74;115:*.avi=1;38;2;79;214;190:*.awk=0;38;2;255;199;119:*.bag=1;38;2;255;117;127:*.bak=0;38;2;68;74;115:*.bat=0;38;2;79;214;190:*.bay=1;38;2;192;153;255:*.bbl=0;38;2;68;74;115:*.bcf=0;38;2;68;74;115:*.bib=0;38;2;255;150;108:*.bin=1;38;2;255;117;127:*.blg=0;38;2;68;74;115:*.bmp=1;38;2;192;153;255:*.bsh=0;38;2;255;199;119:*.bst=0;38;2;255;150;108:*.bz2=1;38;2;255;117;127:*.c++=0;38;2;255;199;119:*.cap=1;38;2;192;153;255:*.cfg=0;38;2;255;150;108:*.cgi=0;38;2;255;199;119:*.clj=0;38;2;255;199;119:*.com=0;38;2;79;214;190:*.cpp=0;38;2;255;199;119:*.cr2=1;38;2;192;153;255:*.cr3=1;38;2;192;153;255:*.crw=1;38;2;192;153;255:*.css=0;38;2;255;199;119:*.csv=0;38;2;200;211;245:*.csx=0;38;2;255;199;119:*.cxx=0;38;2;255;199;119:*.dae=1;38;2;192;153;255:*.dcr=1;38;2;192;153;255:*.dcs=1;38;2;192;153;255:*.deb=1;38;2;255;117;127:*.def=0;38;2;255;199;119:*.dll=0;38;2;79;214;190:*.dmg=1;38;2;255;117;127:*.dng=1;38;2;192;153;255:*.doc=1;38;2;252;167;234:*.dot=0;38;2;255;199;119:*.dox=0;38;2;13;185;215:*.dpr=0;38;2;255;199;119:*.drf=1;38;2;192;153;255:*.dxf=1;38;2;192;153;255:*.eip=1;38;2;192;153;255:*.elc=0;38;2;255;199;119:*.elm=0;38;2;255;199;119:*.epp=0;38;2;255;199;119:*.eps=1;38;2;192;153;255:*.erf=1;38;2;192;153;255:*.erl=0;38;2;255;199;119:*.exe=0;38;2;79;214;190:*.exr=1;38;2;192;153;255:*.exs=0;38;2;255;199;119:*.fbx=1;38;2;192;153;255:*.fff=1;38;2;192;153;255:*.fls=0;38;2;68;74;115:*.flv=1;38;2;79;214;190:*.fnt=1;38;2;13;185;215:*.fon=1;38;2;13;185;215:*.fsi=0;38;2;255;199;119:*.fsx=0;38;2;255;199;119:*.gif=1;38;2;192;153;255:*.git=0;38;2;68;74;115:*.gpr=1;38;2;192;153;255:*.gvy=0;38;2;255;199;119:*.h++=0;38;2;255;199;119:*.hda=1;38;2;192;153;255:*.hip=1;38;2;192;153;255:*.hpp=0;38;2;255;199;119:*.htc=0;38;2;255;199;119:*.htm=0;38;2;200;211;245:*.hxx=0;38;2;255;199;119:*.ico=1;38;2;192;153;255:*.ics=1;38;2;252;167;234:*.idx=0;38;2;68;74;115:*.igs=1;38;2;192;153;255:*.iiq=1;38;2;192;153;255:*.ilg=0;38;2;68;74;115:*.img=1;38;2;255;117;127:*.inc=0;38;2;255;199;119:*.ind=0;38;2;68;74;115:*.ini=0;38;2;255;150;108:*.inl=0;38;2;255;199;119:*.ino=0;38;2;255;199;119:*.ipp=0;38;2;255;199;119:*.iso=1;38;2;255;117;127:*.jar=1;38;2;255;117;127:*.jpg=1;38;2;192;153;255:*.jsx=0;38;2;255;199;119:*.jxl=1;38;2;192;153;255:*.k25=1;38;2;192;153;255:*.kdc=1;38;2;192;153;255:*.kex=1;38;2;252;167;234:*.kra=1;38;2;192;153;255:*.kts=0;38;2;255;199;119:*.log=0;38;2;68;74;115:*.ltx=0;38;2;255;199;119:*.lua=0;38;2;255;199;119:*.m3u=1;38;2;101;188;255:*.m4a=1;38;2;101;188;255:*.m4v=1;38;2;79;214;190:*.mdc=1;38;2;192;153;255:*.mef=1;38;2;192;153;255:*.mid=1;38;2;101;188;255:*.mir=0;38;2;255;199;119:*.mkv=1;38;2;79;214;190:*.mli=0;38;2;255;199;119:*.mos=1;38;2;192;153;255:*.mov=1;38;2;79;214;190:*.mp3=1;38;2;101;188;255:*.mp4=1;38;2;79;214;190:*.mpg=1;38;2;79;214;190:*.mrw=1;38;2;192;153;255:*.msi=1;38;2;255;117;127:*.mtl=1;38;2;192;153;255:*.nef=1;38;2;192;153;255:*.nim=0;38;2;255;199;119:*.nix=0;38;2;255;150;108:*.nrw=1;38;2;192;153;255:*.obj=1;38;2;192;153;255:*.obm=1;38;2;192;153;255:*.odp=1;38;2;252;167;234:*.ods=1;38;2;252;167;234:*.odt=1;38;2;252;167;234:*.ogg=1;38;2;101;188;255:*.ogv=1;38;2;79;214;190:*.orf=1;38;2;192;153;255:*.org=0;38;2;200;211;245:*.otf=1;38;2;13;185;215:*.otl=1;38;2;192;153;255:*.out=0;38;2;68;74;115:*.pas=0;38;2;255;199;119:*.pbm=1;38;2;192;153;255:*.pcx=1;38;2;192;153;255:*.pdf=1;38;2;252;167;234:*.pef=1;38;2;192;153;255:*.pgm=1;38;2;192;153;255:*.php=0;38;2;255;199;119:*.pid=0;38;2;68;74;115:*.pkg=1;38;2;255;117;127:*.png=1;38;2;192;153;255:*.pod=0;38;2;255;199;119:*.ppm=1;38;2;192;153;255:*.pps=1;38;2;252;167;234:*.ppt=1;38;2;252;167;234:*.pro=0;38;2;13;185;215:*.ps1=0;38;2;255;199;119:*.psd=1;38;2;192;153;255:*.ptx=1;38;2;192;153;255:*.pxn=1;38;2;192;153;255:*.pyc=0;38;2;68;74;115:*.pyd=0;38;2;68;74;115:*.pyo=0;38;2;68;74;115:*.qoi=1;38;2;192;153;255:*.r3d=1;38;2;192;153;255:*.raf=1;38;2;192;153;255:*.rar=1;38;2;255;117;127:*.raw=1;38;2;192;153;255:*.rpm=1;38;2;255;117;127:*.rst=0;38;2;200;211;245:*.rtf=1;38;2;252;167;234:*.rw2=1;38;2;192;153;255:*.rwl=1;38;2;192;153;255:*.rwz=1;38;2;192;153;255:*.sbt=0;38;2;255;199;119:*.sql=0;38;2;255;199;119:*.sr2=1;38;2;192;153;255:*.srf=1;38;2;192;153;255:*.srw=1;38;2;192;153;255:*.stl=1;38;2;192;153;255:*.stp=1;38;2;192;153;255:*.sty=0;38;2;68;74;115:*.svg=1;38;2;192;153;255:*.swf=1;38;2;79;214;190:*.swp=0;38;2;68;74;115:*.sxi=1;38;2;252;167;234:*.sxw=1;38;2;252;167;234:*.tar=1;38;2;255;117;127:*.tbz=1;38;2;255;117;127:*.tcl=0;38;2;255;199;119:*.tex=0;38;2;255;199;119:*.tga=1;38;2;192;153;255:*.tgz=1;38;2;255;117;127:*.tif=1;38;2;192;153;255:*.tml=0;38;2;255;150;108:*.tmp=0;38;2;68;74;115:*.toc=0;38;2;68;74;115:*.tsx=0;38;2;255;199;119:*.ttf=1;38;2;13;185;215:*.txt=0;38;2;200;211;245:*.typ=0;38;2;200;211;245:*.usd=1;38;2;192;153;255:*.vcd=1;38;2;255;117;127:*.vim=0;38;2;255;199;119:*.vob=1;38;2;79;214;190:*.vsh=0;38;2;255;199;119:*.wav=1;38;2;101;188;255:*.wma=1;38;2;101;188;255:*.wmv=1;38;2;79;214;190:*.wrl=1;38;2;192;153;255:*.x3d=1;38;2;192;153;255:*.x3f=1;38;2;192;153;255:*.xlr=1;38;2;252;167;234:*.xls=1;38;2;252;167;234:*.xml=0;38;2;200;211;245:*.xmp=0;38;2;255;150;108:*.xpm=1;38;2;192;153;255:*.xvf=1;38;2;192;153;255:*.yml=0;38;2;255;150;108:*.zig=0;38;2;255;199;119:*.zip=1;38;2;255;117;127:*.zsh=0;38;2;255;199;119:*.zst=1;38;2;255;117;127:*TODO=1;38;2;180;249;248:*hgrc=0;38;2;13;185;215:*.avif=1;38;2;192;153;255:*.bash=0;38;2;255;199;119:*.braw=1;38;2;192;153;255:*.conf=0;38;2;255;150;108:*.dart=0;38;2;255;199;119:*.data=1;38;2;192;153;255:*.diff=0;38;2;255;199;119:*.docx=1;38;2;252;167;234:*.epub=1;38;2;252;167;234:*.fish=0;38;2;255;199;119:*.flac=1;38;2;101;188;255:*.h264=1;38;2;79;214;190:*.hack=0;38;2;255;199;119:*.heif=1;38;2;192;153;255:*.hgrc=0;38;2;13;185;215:*.html=0;38;2;200;211;245:*.iges=1;38;2;192;153;255:*.info=0;38;2;200;211;245:*.java=0;38;2;255;199;119:*.jpeg=1;38;2;192;153;255:*.json=0;38;2;255;150;108:*.less=0;38;2;255;199;119:*.lisp=0;38;2;255;199;119:*.lock=0;38;2;68;74;115:*.make=0;38;2;13;185;215:*.mojo=0;38;2;255;199;119:*.mpeg=1;38;2;79;214;190:*.nims=0;38;2;255;199;119:*.opus=1;38;2;101;188;255:*.orig=0;38;2;68;74;115:*.pptx=1;38;2;252;167;234:*.prql=0;38;2;255;199;119:*.psd1=0;38;2;255;199;119:*.psm1=0;38;2;255;199;119:*.purs=0;38;2;255;199;119:*.raku=0;38;2;255;199;119:*.rlib=0;38;2;68;74;115:*.sass=0;38;2;255;199;119:*.scad=0;38;2;255;199;119:*.scss=0;38;2;255;199;119:*.step=1;38;2;192;153;255:*.tbz2=1;38;2;255;117;127:*.tiff=1;38;2;192;153;255:*.toml=0;38;2;255;150;108:*.usda=1;38;2;192;153;255:*.usdc=1;38;2;192;153;255:*.usdz=1;38;2;192;153;255:*.webm=1;38;2;79;214;190:*.webp=1;38;2;192;153;255:*.woff=1;38;2;13;185;215:*.xbps=1;38;2;255;117;127:*.xlsx=1;38;2;252;167;234:*.yaml=0;38;2;255;150;108:*stdin=0;38;2;68;74;115:*v.mod=0;38;2;13;185;215:*.blend=1;38;2;192;153;255:*.cabal=0;38;2;255;199;119:*.cache=0;38;2;68;74;115:*.class=0;38;2;68;74;115:*.cmake=0;38;2;13;185;215:*.ctags=0;38;2;68;74;115:*.dylib=0;38;2;79;214;190:*.dyn_o=0;38;2;68;74;115:*.gcode=0;38;2;255;199;119:*.ipynb=0;38;2;255;199;119:*.mdown=0;38;2;200;211;245:*.patch=0;38;2;255;199;119:*.rmeta=0;38;2;68;74;115:*.scala=0;38;2;255;199;119:*.shtml=0;38;2;200;211;245:*.swift=0;38;2;255;199;119:*.toast=1;38;2;255;117;127:*.woff2=1;38;2;13;185;215:*.xhtml=0;38;2;200;211;245:*Icon\r=0;38;2;68;74;115:*LEGACY=1;38;2;137;221;255:*NOTICE=1;38;2;137;221;255:*README=1;38;2;137;221;255:*go.mod=0;38;2;13;185;215:*go.sum=0;38;2;68;74;115:*passwd=0;38;2;255;150;108:*shadow=0;38;2;255;150;108:*stderr=0;38;2;68;74;115:*stdout=0;38;2;68;74;115:*.bashrc=0;38;2;255;199;119:*.config=0;38;2;255;150;108:*.dyn_hi=0;38;2;68;74;115:*.flake8=0;38;2;13;185;215:*.gradle=0;38;2;255;199;119:*.groovy=0;38;2;255;199;119:*.ignore=0;38;2;13;185;215:*.matlab=0;38;2;255;199;119:*.nimble=0;38;2;255;199;119:*COPYING=1;38;2;200;211;245:*INSTALL=1;38;2;137;221;255:*LICENCE=1;38;2;200;211;245:*LICENSE=1;38;2;200;211;245:*TODO.md=1;38;2;180;249;248:*VERSION=1;38;2;137;221;255:*.alembic=1;38;2;192;153;255:*.desktop=0;38;2;255;150;108:*.gemspec=0;38;2;13;185;215:*.mailmap=0;38;2;13;185;215:*Doxyfile=0;38;2;13;185;215:*Makefile=0;38;2;13;185;215:*TODO.txt=1;38;2;180;249;248:*setup.py=0;38;2;13;185;215:*.DS_Store=0;38;2;68;74;115:*.cmake.in=0;38;2;13;185;215:*.fdignore=0;38;2;13;185;215:*.kdevelop=0;38;2;13;185;215:*.markdown=0;38;2;200;211;245:*.rgignore=0;38;2;13;185;215:*.tfignore=0;38;2;13;185;215:*CHANGELOG=1;38;2;137;221;255:*COPYRIGHT=1;38;2;200;211;245:*README.md=1;38;2;137;221;255:*bun.lockb=0;38;2;68;74;115:*configure=0;38;2;13;185;215:*.gitconfig=0;38;2;13;185;215:*.gitignore=0;38;2;13;185;215:*.localized=0;38;2;68;74;115:*.scons_opt=0;38;2;68;74;115:*.timestamp=0;38;2;68;74;115:*CODEOWNERS=0;38;2;13;185;215:*Dockerfile=0;38;2;88;158;215:*INSTALL.md=1;38;2;137;221;255:*README.txt=1;38;2;137;221;255:*SConscript=0;38;2;13;185;215:*SConstruct=0;38;2;13;185;215:*.cirrus.yml=0;38;2;88;158;215:*.gitmodules=0;38;2;13;185;215:*.synctex.gz=0;38;2;68;74;115:*.travis.yml=0;38;2;88;158;215:*INSTALL.txt=1;38;2;137;221;255:*LICENSE-MIT=1;38;2;200;211;245:*MANIFEST.in=0;38;2;13;185;215:*Makefile.am=0;38;2;13;185;215:*Makefile.in=0;38;2;68;74;115:*.applescript=0;38;2;255;199;119:*.fdb_latexmk=0;38;2;68;74;115:*.webmanifest=0;38;2;255;150;108:*CHANGELOG.md=1;38;2;137;221;255:*CONTRIBUTING=1;38;2;137;221;255:*CONTRIBUTORS=1;38;2;137;221;255:*appveyor.yml=0;38;2;88;158;215:*configure.ac=0;38;2;13;185;215:*.bash_profile=0;38;2;255;199;119:*.clang-format=0;38;2;13;185;215:*.editorconfig=0;38;2;13;185;215:*CHANGELOG.txt=1;38;2;137;221;255:*.gitattributes=0;38;2;13;185;215:*.gitlab-ci.yml=0;38;2;88;158;215:*CMakeCache.txt=0;38;2;68;74;115:*CMakeLists.txt=0;38;2;13;185;215:*LICENSE-APACHE=1;38;2;200;211;245:*pyproject.toml=0;38;2;13;185;215:*CODE_OF_CONDUCT=1;38;2;137;221;255:*CONTRIBUTING.md=1;38;2;137;221;255:*CONTRIBUTORS.md=1;38;2;137;221;255:*.sconsign.dblite=0;38;2;68;74;115:*CONTRIBUTING.txt=1;38;2;137;221;255:*CONTRIBUTORS.txt=1;38;2;137;221;255:*requirements.txt=0;38;2;13;185;215:*package-lock.json=0;38;2;68;74;115:*CODE_OF_CONDUCT.md=1;38;2;137;221;255:*.CFUserTextEncoding=0;38;2;68;74;115:*CODE_OF_CONDUCT.txt=1;38;2;137;221;255:*azure-pipelines.yml=0;38;2;88;158;215"
# rose-pine-moon:
export LS_COLORS="*~=0;38;2;57;53;82:bd=0;38;2;196;167;231;48;2;42;39;63:ca=0:cd=0;38;2;234;154;151;48;2;42;39;63:di=0;38;2;156;207;216:do=0;38;2;224;222;244;48;2;234;154;151:ex=1;38;2;234;154;151:fi=0:ln=0;38;2;235;111;146:mh=0:mi=0;38;2;224;222;244;48;2;234;154;151:no=0:or=0;38;2;224;222;244;48;2;234;154;151:ow=0:pi=0;38;2;224;222;244;48;2;62;143;176:rs=0:sg=0:so=0;38;2;224;222;244;48;2;234;154;151:st=0:su=0:tw=0:*.1=0;38;2;246;193;119:*.a=1;38;2;234;154;151:*.c=0;38;2;62;143;176:*.d=0;38;2;62;143;176:*.h=0;38;2;62;143;176:*.m=0;38;2;62;143;176:*.o=0;38;2;57;53;82:*.p=0;38;2;62;143;176:*.r=0;38;2;62;143;176:*.t=0;38;2;62;143;176:*.v=0;38;2;62;143;176:*.z=4;38;2;156;207;216:*.7z=4;38;2;156;207;216:*.ai=0;38;2;235;111;146:*.as=0;38;2;62;143;176:*.bc=0;38;2;57;53;82:*.bz=4;38;2;156;207;216:*.cc=0;38;2;62;143;176:*.cp=0;38;2;62;143;176:*.cr=0;38;2;62;143;176:*.cs=0;38;2;62;143;176:*.db=4;38;2;156;207;216:*.di=0;38;2;62;143;176:*.el=0;38;2;62;143;176:*.ex=0;38;2;62;143;176:*.fs=0;38;2;62;143;176:*.go=0;38;2;62;143;176:*.gv=0;38;2;62;143;176:*.gz=4;38;2;156;207;216:*.ha=0;38;2;62;143;176:*.hh=0;38;2;62;143;176:*.hi=0;38;2;57;53;82:*.hs=0;38;2;62;143;176:*.jl=0;38;2;62;143;176:*.js=0;38;2;62;143;176:*.ko=1;38;2;234;154;151:*.kt=0;38;2;62;143;176:*.la=0;38;2;57;53;82:*.ll=0;38;2;62;143;176:*.lo=0;38;2;57;53;82:*.ma=0;38;2;235;111;146:*.mb=0;38;2;235;111;146:*.md=0;38;2;246;193;119:*.mk=0;38;2;156;207;216:*.ml=0;38;2;62;143;176:*.mn=0;38;2;62;143;176:*.nb=0;38;2;62;143;176:*.nu=0;38;2;62;143;176:*.pl=0;38;2;62;143;176:*.pm=0;38;2;62;143;176:*.pp=0;38;2;62;143;176:*.ps=0;38;2;196;167;231:*.py=0;38;2;62;143;176:*.rb=0;38;2;62;143;176:*.rm=0;38;2;235;111;146:*.rs=0;38;2;62;143;176:*.sh=0;38;2;62;143;176:*.so=1;38;2;234;154;151:*.td=0;38;2;62;143;176:*.ts=0;38;2;62;143;176:*.ui=0;38;2;246;193;119:*.vb=0;38;2;62;143;176:*.wv=0;38;2;235;111;146:*.xz=4;38;2;156;207;216:*FAQ=0;38;2;35;33;54;48;2;246;193;119:*.3ds=0;38;2;235;111;146:*.3fr=0;38;2;235;111;146:*.3mf=0;38;2;235;111;146:*.adb=0;38;2;62;143;176:*.ads=0;38;2;62;143;176:*.aif=0;38;2;235;111;146:*.amf=0;38;2;235;111;146:*.ape=0;38;2;235;111;146:*.apk=4;38;2;156;207;216:*.ari=0;38;2;235;111;146:*.arj=4;38;2;156;207;216:*.arw=0;38;2;235;111;146:*.asa=0;38;2;62;143;176:*.asm=0;38;2;62;143;176:*.aux=0;38;2;57;53;82:*.avi=0;38;2;235;111;146:*.awk=0;38;2;62;143;176:*.bag=4;38;2;156;207;216:*.bak=0;38;2;57;53;82:*.bat=1;38;2;234;154;151:*.bay=0;38;2;235;111;146:*.bbl=0;38;2;57;53;82:*.bcf=0;38;2;57;53;82:*.bib=0;38;2;246;193;119:*.bin=4;38;2;156;207;216:*.blg=0;38;2;57;53;82:*.bmp=0;38;2;235;111;146:*.bsh=0;38;2;62;143;176:*.bst=0;38;2;246;193;119:*.bz2=4;38;2;156;207;216:*.c++=0;38;2;62;143;176:*.cap=0;38;2;235;111;146:*.cfg=0;38;2;246;193;119:*.cgi=0;38;2;62;143;176:*.clj=0;38;2;62;143;176:*.com=1;38;2;234;154;151:*.cpp=0;38;2;62;143;176:*.cr2=0;38;2;235;111;146:*.cr3=0;38;2;235;111;146:*.crw=0;38;2;235;111;146:*.css=0;38;2;62;143;176:*.csv=0;38;2;246;193;119:*.csx=0;38;2;62;143;176:*.cxx=0;38;2;62;143;176:*.dae=0;38;2;235;111;146:*.dcr=0;38;2;235;111;146:*.dcs=0;38;2;235;111;146:*.deb=4;38;2;156;207;216:*.def=0;38;2;62;143;176:*.dll=1;38;2;234;154;151:*.dmg=4;38;2;156;207;216:*.dng=0;38;2;235;111;146:*.doc=0;38;2;196;167;231:*.dot=0;38;2;62;143;176:*.dox=0;38;2;156;207;216:*.dpr=0;38;2;62;143;176:*.drf=0;38;2;235;111;146:*.dxf=0;38;2;235;111;146:*.eip=0;38;2;235;111;146:*.elc=0;38;2;62;143;176:*.elm=0;38;2;62;143;176:*.epp=0;38;2;62;143;176:*.eps=0;38;2;235;111;146:*.erf=0;38;2;235;111;146:*.erl=0;38;2;62;143;176:*.exe=1;38;2;234;154;151:*.exr=0;38;2;235;111;146:*.exs=0;38;2;62;143;176:*.fbx=0;38;2;235;111;146:*.fff=0;38;2;235;111;146:*.fls=0;38;2;57;53;82:*.flv=0;38;2;235;111;146:*.fnt=0;38;2;235;111;146:*.fon=0;38;2;235;111;146:*.fsi=0;38;2;62;143;176:*.fsx=0;38;2;62;143;176:*.gif=0;38;2;235;111;146:*.git=0;38;2;57;53;82:*.gpr=0;38;2;235;111;146:*.gvy=0;38;2;62;143;176:*.h++=0;38;2;62;143;176:*.hda=0;38;2;235;111;146:*.hip=0;38;2;235;111;146:*.hpp=0;38;2;62;143;176:*.htc=0;38;2;62;143;176:*.htm=0;38;2;246;193;119:*.hxx=0;38;2;62;143;176:*.ico=0;38;2;235;111;146:*.ics=0;38;2;196;167;231:*.idx=0;38;2;57;53;82:*.igs=0;38;2;235;111;146:*.iiq=0;38;2;235;111;146:*.ilg=0;38;2;57;53;82:*.img=4;38;2;156;207;216:*.inc=0;38;2;62;143;176:*.ind=0;38;2;57;53;82:*.ini=0;38;2;246;193;119:*.inl=0;38;2;62;143;176:*.ino=0;38;2;62;143;176:*.ipp=0;38;2;62;143;176:*.iso=4;38;2;156;207;216:*.jar=4;38;2;156;207;216:*.jpg=0;38;2;235;111;146:*.jsx=0;38;2;62;143;176:*.jxl=0;38;2;235;111;146:*.k25=0;38;2;235;111;146:*.kdc=0;38;2;235;111;146:*.kex=0;38;2;196;167;231:*.kra=0;38;2;235;111;146:*.kts=0;38;2;62;143;176:*.log=0;38;2;57;53;82:*.ltx=0;38;2;62;143;176:*.lua=0;38;2;62;143;176:*.m3u=0;38;2;235;111;146:*.m4a=0;38;2;235;111;146:*.m4v=0;38;2;235;111;146:*.mdc=0;38;2;235;111;146:*.mef=0;38;2;235;111;146:*.mid=0;38;2;235;111;146:*.mir=0;38;2;62;143;176:*.mkv=0;38;2;235;111;146:*.mli=0;38;2;62;143;176:*.mos=0;38;2;235;111;146:*.mov=0;38;2;235;111;146:*.mp3=0;38;2;235;111;146:*.mp4=0;38;2;235;111;146:*.mpg=0;38;2;235;111;146:*.mrw=0;38;2;235;111;146:*.msi=4;38;2;156;207;216:*.mtl=0;38;2;235;111;146:*.nef=0;38;2;235;111;146:*.nim=0;38;2;62;143;176:*.nix=0;38;2;246;193;119:*.nrw=0;38;2;235;111;146:*.obj=0;38;2;235;111;146:*.obm=0;38;2;235;111;146:*.odp=0;38;2;196;167;231:*.ods=0;38;2;196;167;231:*.odt=0;38;2;196;167;231:*.ogg=0;38;2;235;111;146:*.ogv=0;38;2;235;111;146:*.orf=0;38;2;235;111;146:*.org=0;38;2;246;193;119:*.otf=0;38;2;235;111;146:*.otl=0;38;2;235;111;146:*.out=0;38;2;57;53;82:*.pas=0;38;2;62;143;176:*.pbm=0;38;2;235;111;146:*.pcx=0;38;2;235;111;146:*.pdf=0;38;2;196;167;231:*.pef=0;38;2;235;111;146:*.pgm=0;38;2;235;111;146:*.php=0;38;2;62;143;176:*.pid=0;38;2;57;53;82:*.pkg=4;38;2;156;207;216:*.png=0;38;2;235;111;146:*.pod=0;38;2;62;143;176:*.ppm=0;38;2;235;111;146:*.pps=0;38;2;196;167;231:*.ppt=0;38;2;196;167;231:*.pro=0;38;2;156;207;216:*.ps1=0;38;2;62;143;176:*.psd=0;38;2;235;111;146:*.ptx=0;38;2;235;111;146:*.pxn=0;38;2;235;111;146:*.pyc=0;38;2;57;53;82:*.pyd=0;38;2;57;53;82:*.pyo=0;38;2;57;53;82:*.qoi=0;38;2;235;111;146:*.r3d=0;38;2;235;111;146:*.raf=0;38;2;235;111;146:*.rar=4;38;2;156;207;216:*.raw=0;38;2;235;111;146:*.rpm=4;38;2;156;207;216:*.rst=0;38;2;246;193;119:*.rtf=0;38;2;196;167;231:*.rw2=0;38;2;235;111;146:*.rwl=0;38;2;235;111;146:*.rwz=0;38;2;235;111;146:*.sbt=0;38;2;62;143;176:*.sql=0;38;2;62;143;176:*.sr2=0;38;2;235;111;146:*.srf=0;38;2;235;111;146:*.srw=0;38;2;235;111;146:*.stl=0;38;2;235;111;146:*.stp=0;38;2;235;111;146:*.sty=0;38;2;57;53;82:*.svg=0;38;2;235;111;146:*.swf=0;38;2;235;111;146:*.swp=0;38;2;57;53;82:*.sxi=0;38;2;196;167;231:*.sxw=0;38;2;196;167;231:*.tar=4;38;2;156;207;216:*.tbz=4;38;2;156;207;216:*.tcl=0;38;2;62;143;176:*.tex=0;38;2;62;143;176:*.tga=0;38;2;235;111;146:*.tgz=4;38;2;156;207;216:*.tif=0;38;2;235;111;146:*.tml=0;38;2;246;193;119:*.tmp=0;38;2;57;53;82:*.toc=0;38;2;57;53;82:*.tsx=0;38;2;62;143;176:*.ttf=0;38;2;235;111;146:*.txt=0;38;2;246;193;119:*.typ=0;38;2;246;193;119:*.usd=0;38;2;235;111;146:*.vcd=4;38;2;156;207;216:*.vim=0;38;2;62;143;176:*.vob=0;38;2;235;111;146:*.vsh=0;38;2;62;143;176:*.wav=0;38;2;235;111;146:*.wma=0;38;2;235;111;146:*.wmv=0;38;2;235;111;146:*.wrl=0;38;2;235;111;146:*.x3d=0;38;2;235;111;146:*.x3f=0;38;2;235;111;146:*.xlr=0;38;2;196;167;231:*.xls=0;38;2;196;167;231:*.xml=0;38;2;246;193;119:*.xmp=0;38;2;246;193;119:*.xpm=0;38;2;235;111;146:*.xvf=0;38;2;235;111;146:*.yml=0;38;2;246;193;119:*.zig=0;38;2;62;143;176:*.zip=4;38;2;156;207;216:*.zsh=0;38;2;62;143;176:*.zst=4;38;2;156;207;216:*TODO=1:*hgrc=0;38;2;156;207;216:*.avif=0;38;2;235;111;146:*.bash=0;38;2;62;143;176:*.braw=0;38;2;235;111;146:*.conf=0;38;2;246;193;119:*.dart=0;38;2;62;143;176:*.data=0;38;2;235;111;146:*.diff=0;38;2;62;143;176:*.docx=0;38;2;196;167;231:*.epub=0;38;2;196;167;231:*.fish=0;38;2;62;143;176:*.flac=0;38;2;235;111;146:*.h264=0;38;2;235;111;146:*.hack=0;38;2;62;143;176:*.heif=0;38;2;235;111;146:*.hgrc=0;38;2;156;207;216:*.html=0;38;2;246;193;119:*.iges=0;38;2;235;111;146:*.info=0;38;2;246;193;119:*.java=0;38;2;62;143;176:*.jpeg=0;38;2;235;111;146:*.json=0;38;2;246;193;119:*.less=0;38;2;62;143;176:*.lisp=0;38;2;62;143;176:*.lock=0;38;2;57;53;82:*.make=0;38;2;156;207;216:*.mojo=0;38;2;62;143;176:*.mpeg=0;38;2;235;111;146:*.nims=0;38;2;62;143;176:*.opus=0;38;2;235;111;146:*.orig=0;38;2;57;53;82:*.pptx=0;38;2;196;167;231:*.prql=0;38;2;62;143;176:*.psd1=0;38;2;62;143;176:*.psm1=0;38;2;62;143;176:*.purs=0;38;2;62;143;176:*.raku=0;38;2;62;143;176:*.rlib=0;38;2;57;53;82:*.sass=0;38;2;62;143;176:*.scad=0;38;2;62;143;176:*.scss=0;38;2;62;143;176:*.step=0;38;2;235;111;146:*.tbz2=4;38;2;156;207;216:*.tiff=0;38;2;235;111;146:*.toml=0;38;2;246;193;119:*.usda=0;38;2;235;111;146:*.usdc=0;38;2;235;111;146:*.usdz=0;38;2;235;111;146:*.webm=0;38;2;235;111;146:*.webp=0;38;2;235;111;146:*.woff=0;38;2;235;111;146:*.xbps=4;38;2;156;207;216:*.xlsx=0;38;2;196;167;231:*.yaml=0;38;2;246;193;119:*stdin=0;38;2;57;53;82:*v.mod=0;38;2;156;207;216:*.blend=0;38;2;235;111;146:*.cabal=0;38;2;62;143;176:*.cache=0;38;2;57;53;82:*.class=0;38;2;57;53;82:*.cmake=0;38;2;156;207;216:*.ctags=0;38;2;57;53;82:*.dylib=1;38;2;234;154;151:*.dyn_o=0;38;2;57;53;82:*.gcode=0;38;2;62;143;176:*.ipynb=0;38;2;62;143;176:*.mdown=0;38;2;246;193;119:*.patch=0;38;2;62;143;176:*.rmeta=0;38;2;57;53;82:*.scala=0;38;2;62;143;176:*.shtml=0;38;2;246;193;119:*.swift=0;38;2;62;143;176:*.toast=4;38;2;156;207;216:*.woff2=0;38;2;235;111;146:*.xhtml=0;38;2;246;193;119:*Icon\r=0;38;2;57;53;82:*LEGACY=0;38;2;35;33;54;48;2;246;193;119:*NOTICE=0;38;2;35;33;54;48;2;246;193;119:*README=0;38;2;35;33;54;48;2;246;193;119:*go.mod=0;38;2;156;207;216:*go.sum=0;38;2;57;53;82:*passwd=0;38;2;246;193;119:*shadow=0;38;2;246;193;119:*stderr=0;38;2;57;53;82:*stdout=0;38;2;57;53;82:*.bashrc=0;38;2;62;143;176:*.config=0;38;2;246;193;119:*.dyn_hi=0;38;2;57;53;82:*.flake8=0;38;2;156;207;216:*.gradle=0;38;2;62;143;176:*.groovy=0;38;2;62;143;176:*.ignore=0;38;2;156;207;216:*.matlab=0;38;2;62;143;176:*.nimble=0;38;2;62;143;176:*COPYING=0;38;2;110;106;134:*INSTALL=0;38;2;35;33;54;48;2;246;193;119:*LICENCE=0;38;2;110;106;134:*LICENSE=0;38;2;110;106;134:*TODO.md=1:*VERSION=0;38;2;35;33;54;48;2;246;193;119:*.alembic=0;38;2;235;111;146:*.desktop=0;38;2;246;193;119:*.gemspec=0;38;2;156;207;216:*.mailmap=0;38;2;156;207;216:*Doxyfile=0;38;2;156;207;216:*Makefile=0;38;2;156;207;216:*TODO.txt=1:*setup.py=0;38;2;156;207;216:*.DS_Store=0;38;2;57;53;82:*.cmake.in=0;38;2;156;207;216:*.fdignore=0;38;2;156;207;216:*.kdevelop=0;38;2;156;207;216:*.markdown=0;38;2;246;193;119:*.rgignore=0;38;2;156;207;216:*.tfignore=0;38;2;156;207;216:*CHANGELOG=0;38;2;35;33;54;48;2;246;193;119:*COPYRIGHT=0;38;2;110;106;134:*README.md=0;38;2;35;33;54;48;2;246;193;119:*bun.lockb=0;38;2;57;53;82:*configure=0;38;2;156;207;216:*.gitconfig=0;38;2;156;207;216:*.gitignore=0;38;2;156;207;216:*.localized=0;38;2;57;53;82:*.scons_opt=0;38;2;57;53;82:*.timestamp=0;38;2;57;53;82:*CODEOWNERS=0;38;2;156;207;216:*Dockerfile=0;38;2;246;193;119:*INSTALL.md=0;38;2;35;33;54;48;2;246;193;119:*README.txt=0;38;2;35;33;54;48;2;246;193;119:*SConscript=0;38;2;156;207;216:*SConstruct=0;38;2;156;207;216:*.cirrus.yml=0;38;2;156;207;216:*.gitmodules=0;38;2;156;207;216:*.synctex.gz=0;38;2;57;53;82:*.travis.yml=0;38;2;156;207;216:*INSTALL.txt=0;38;2;35;33;54;48;2;246;193;119:*LICENSE-MIT=0;38;2;110;106;134:*MANIFEST.in=0;38;2;156;207;216:*Makefile.am=0;38;2;156;207;216:*Makefile.in=0;38;2;57;53;82:*.applescript=0;38;2;62;143;176:*.fdb_latexmk=0;38;2;57;53;82:*.webmanifest=0;38;2;246;193;119:*CHANGELOG.md=0;38;2;35;33;54;48;2;246;193;119:*CONTRIBUTING=0;38;2;35;33;54;48;2;246;193;119:*CONTRIBUTORS=0;38;2;35;33;54;48;2;246;193;119:*appveyor.yml=0;38;2;156;207;216:*configure.ac=0;38;2;156;207;216:*.bash_profile=0;38;2;62;143;176:*.clang-format=0;38;2;156;207;216:*.editorconfig=0;38;2;156;207;216:*CHANGELOG.txt=0;38;2;35;33;54;48;2;246;193;119:*.gitattributes=0;38;2;156;207;216:*.gitlab-ci.yml=0;38;2;156;207;216:*CMakeCache.txt=0;38;2;57;53;82:*CMakeLists.txt=0;38;2;156;207;216:*LICENSE-APACHE=0;38;2;110;106;134:*pyproject.toml=0;38;2;156;207;216:*CODE_OF_CONDUCT=0;38;2;35;33;54;48;2;246;193;119:*CONTRIBUTING.md=0;38;2;35;33;54;48;2;246;193;119:*CONTRIBUTORS.md=0;38;2;35;33;54;48;2;246;193;119:*.sconsign.dblite=0;38;2;57;53;82:*CONTRIBUTING.txt=0;38;2;35;33;54;48;2;246;193;119:*CONTRIBUTORS.txt=0;38;2;35;33;54;48;2;246;193;119:*requirements.txt=0;38;2;156;207;216:*package-lock.json=0;38;2;57;53;82:*CODE_OF_CONDUCT.md=0;38;2;35;33;54;48;2;246;193;119:*.CFUserTextEncoding=0;38;2;57;53;82:*CODE_OF_CONDUCT.txt=0;38;2;35;33;54;48;2;246;193;119:*azure-pipelines.yml=0;38;2;156;207;216"

# modify zsh to not bind to ctrl + h,j,k,l (i want them for vim/tmux)
bindkey -r "^H" &>/dev/null
bindkey -r "^J" &>/dev/null
bindkey -r "^K" &>/dev/null
bindkey -r "^L" &>/dev/null

# Exit virtualenv if present (this is just because I cant find where its activating.......)
deactivate &>/dev/null
export DOTFILES_FOLDER=$HOME/dotfiles
export XDG_CONFIG_HOME=$HOME/.config

# Load any dependencies in the dependencies directory
# NOTE(ayubun): erm, this breaks because i repurposed the depedencies folder to include scripts that shouldn't be run without commands,
# i.e. tmux-love.sh, which is a helper script to attach to an existing tmux session if present (else create it). point is, we dont want
# to run all the scripts in that dir anymore lol
# find $HOME/dotfiles/configs/dependencies -maxdepth 1 -mindepth 1 -type f -print | \
# while read file; do
#     file=$(basename ${file})
#     . $HOME/dotfiles/configs/dependencies/$file
# done

# Kubectl autocomplete
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)  # setup autocomplete
alias k=kubectl
complete -o default -F __start_kubectl k

# Nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="/home/discord/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH=/home/discord/.local/bin/:$PATH

# bun completions
[ -s "/Users/ayu/.bun/_bun" ] && source "/Users/ayu/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Load any pre-configured functions
if [ -f "$DOTFILES_FOLDER/configs/dependencies/functions.sh" ]; then
  source "$DOTFILES_FOLDER/configs/dependencies/functions.sh"
fi
# Load any pre-configured aliases
if [ -f $DOTFILES_FOLDER/configs/dependencies/.zshrc_aliases ]; then
  . $DOTFILES_FOLDER/configs/dependencies/.zshrc_aliases
fi
# Load any private work aliases
if [ -f $HOME/work/.zshrc_aliases ]; then
  . $HOME/work/.zshrc_aliases
fi

# Bins
add_to_path "$HOME/discord/.local/bin"
add_to_path "$HOME/.local/bin"
add_discord_bin_to_usr_local_bin "coder2" "coder"

# asdf
. "$HOME/.asdf/asdf.sh" &>/dev/null
. "$HOME/.asdf/completions/asdf.bash" &>/dev/null

if [[ "$OSTYPE" == "darwin"* ]]; then
    # Add code cmd (only works on mac)
    add_to_path "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

# tmux dead session checker lol
# if [[ "$TMUX" ]]; then
#   export TMUX_SESSION_NAME="$(tmux display-message -p '#S')"
#   if [[ "$TMUX_SESSION_NAME" != "ghostty" ]]; then
#     tmux set-hook -t 'ghostty' 'run-shell "~/dotfiles/configs/dependencies/tmux-monitor.sh"'
#   fi
# fi

# git repository greeter https://github.com/o2sh/onefetch/wiki/getting-started
last_repository=
check_directory_for_new_repository() {
	current_repository=$(git rev-parse --show-toplevel 2> /dev/null)
	
	if [ "$current_repository" ] && \
	   [ "$current_repository" != "$last_repository" ]; then
                echo ""
		onefetch
	fi
	last_repository=$current_repository
}
# cd() {
# 	builtin cd "$@"
# 	check_directory_for_new_repository
# }
# end git repository greeter

# Run neofetch on terminal login! (just looks kinda cool :3)
if ! [[ "$TMUX" ]]; then
  # it's kind of annoying to run this when panes are smaller so ill only run it if it's not a tmux session :o
  neofetch
fi

# optional, greet also when opening shell directly in repository directory
# adds time to startup
# check_directory_for_new_repository &>/dev/null

# Added by Windsurf
export PATH="/Users/ayu/.codeium/windsurf/bin:$PATH"

# eval "$(starship init zsh)"


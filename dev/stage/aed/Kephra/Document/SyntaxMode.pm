use v5.12;
use warnings;
use Exporter;

package Kephra::Document::SyntaxMode;
our @ISA = qw(Exporter);
our @EXPORT = qw/set_mode set_mode_from_file_ending rot_syntaxmode/;
use Kephra::API qw(app_window);

my %file_end = ( perl => [qw/pod pl pm plx pl6/],
                 tex  => [qw/tex latex/],
                 yaml => [qw/yml yaml/],
                 no =>   [qw/txt/],
);
my @mode = keys %file_end; push @mode, $mode[0];


sub set_mode {
	my ($self, $mode) = @_;
	$mode = $self->{'syntaxmode'} unless defined $mode;
	if    ($mode eq 'no')  {set_highlight_no($self)}
	elsif ($mode eq 'perl'){set_highlight_perl($self)}
	elsif ($mode eq 'tex') {set_highlight_tex($self)}
	elsif ($mode eq 'yaml'){set_highlight_yaml($self)}
	$self->{'syntaxmode'} = $mode;
	app_window()->SetStatusText( $self->{'syntaxmode'}, 1);
}

sub set_mode_from_file_ending {
	my ($self) = @_;
	$self->set_mode( guess_mode_from_file_ending($self) );
}

sub guess_mode_from_file_ending {
	my ($self, $default_syntaxmode) = @_;
	my $syntaxmode = $default_syntaxmode;
	if ($self->{'file_ending'}) {
		for my $modename (keys %file_end){
			for (@{$file_end{$modename}}) 
				{$syntaxmode = $modename if $self->{'file_ending'} eq $_}
		}
	}
	return $syntaxmode;
}

sub rot_syntaxmode {
	my $self = shift;
	for (1 .. $#mode){
		($self->{'syntaxmode'} = $mode[$_-1]),last  if $self->{'syntaxmode'} eq $mode[$_]
	}
	$self->set_mode();
}

################################################################################

sub set_highlight_no {
	my ($self) = @_;
	my $ed = $self->{'editor'};
	$ed->StyleClearAll;
	$ed->SetLexer( &Wx::wxSTC_LEX_NULL );
	$ed->SetKeyWords(0, '');
}

sub set_highlight_perl {
	my ($self) = @_;
	my $ed = $self->{'editor'};
	$ed->StyleClearAll;
	$ed->SetLexer( &Wx::wxSTC_LEX_PERL );
	$ed->SetKeyWords(0, 'NULL 
__FILE__ __LINE__ __PACKAGE__ __DATA__ __END__ __WARN__ __DIE__
AUTOLOAD BEGIN CHECK CORE DESTROY END EQ GE GT INIT LE LT NE UNITCHECK 
abs accept alarm and atan2 bind binmode bless break
caller chdir chmod chomp chop chown chr chroot close closedir cmp connect
continue cos crypt
dbmclose dbmopen default defined delete die do dump
each else elsif endgrent endhostent endnetent endprotoent endpwent endservent 
eof eq eval exec exists exit exp 
fcntl fileno flock for foreach fork format formline 
ge getc getgrent getgrgid getgrnam gethostbyaddr gethostbyname gethostent 
getlogin getnetbyaddr getnetbyname getnetent getpeername getpgrp getppid 
getpriority getprotobyname getprotobynumber getprotoent getpwent getpwnam 
getpwuid getservbyname getservbyport getservent getsockname getsockopt given 
glob gmtime goto grep gt 
hex if index int ioctl join keys kill 
last lc lcfirst le length link listen local localtime lock log lstat lt 
m map mkdir msgctl msgget msgrcv msgsnd my ne next no not 
oct open opendir or ord our pack package pipe pop pos print printf prototype push 
q qq qr quotemeta qu qw qx 
rand read readdir readline readlink readpipe recv redo ref rename require reset 
return reverse rewinddir rindex rmdir
s say scalar seek seekdir select semctl semget semop send setgrent sethostent 
setnetent setpgrp setpriority setprotoent setpwent setservent setsockopt shift 
shmctl shmget shmread shmwrite shutdown sin sleep socket socketpair sort splice 
split sprintf sqrt srand stat state study sub substr symlink syscall sysopen 
sysread sysseek system syswrite 
tell telldir tie tied time times tr truncate
uc ucfirst umask undef unless unlink unpack unshift untie until use utime 
values vec wait waitpid wantarray warn when while write x xor y');
# Add new keyword.
# $_[0]->StyleSetSpec( &Wx::wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)

	$ed->StyleSetSpec(1,"fore:#ff0000");                                     # Error
	$ed->StyleSetSpec(2,"fore:#aaaaaa");                                     # Comment
	$ed->StyleSetSpec(3,"fore:#004000,back:#E0FFE0,$(font.text),eolfilled"); # POD: = at beginning of line
	$ed->StyleSetSpec(&Wx::wxSTC_PL_NUMBER,"fore:#007f7f");                                     # Number
	$ed->StyleSetSpec(5,"fore:#000077,bold");                                # Keywords #
	$ed->StyleSetSpec(6,"fore:#ee7b00,back:#fff8f8");                        # Doublequoted string
	$ed->StyleSetSpec(7,"fore:#f36600,back:#fffcff");                        # Single quoted string
	$ed->StyleSetSpec(8,"fore:#555555");                                     # Symbols / Punctuation. Currently not used by LexPerl.
	$ed->StyleSetSpec(9,"");                                                 # Preprocessor. Currently not used by LexPerl.
	$ed->StyleSetSpec(10,"fore:#002200");                                    # Operators
	$ed->StyleSetSpec(11,"fore:#3355bb");                                    # Identifiers (functions, etc.)
	$ed->StyleSetSpec(12,"fore:#228822");                                    # Scalars: $var
	$ed->StyleSetSpec(13,"fore:#339933");                                    # Array: @var
	$ed->StyleSetSpec(14,"fore:#44aa44");                                    # Hash: %var
	$ed->StyleSetSpec(15,"fore:#55bb55");                                    # Symbol table: *var
	$ed->StyleSetSpec(17,"fore:#000000,back:#A0FFA0");                       # Regex: /re/ or m{re}
	$ed->StyleSetSpec(18,"fore:#000000,back:#F0E080");                       # Substitution: s/re/ore/
	$ed->StyleSetSpec(19,"fore:#000000,back:#8080A0");                       # Long Quote (qq, qr, qw, qx) -- obsolete: replaced by qq, qx, qr, qw
	$ed->StyleSetSpec(20,"fore:#ff7700,back:#f9f9d7");                       # Back Ticks
	$ed->StyleSetSpec(21,"fore:#600000,back:#FFF0D8,eolfilled");             # Data Section: __DATA__ or __END__ at beginning of line
	$ed->StyleSetSpec(22,"fore:#000000,back:#DDD0DD");                       # Here-doc (delimiter)
	$ed->StyleSetSpec(23,"fore:#7F007F,back:#DDD0DD,eolfilled,notbold");     # Here-doc (single quoted, q)
	$ed->StyleSetSpec(24,"fore:#7F007F,back:#DDD0DD,eolfilled,bold");        # Here-doc (double quoted, qq)
	$ed->StyleSetSpec(25,"fore:#7F007F,back:#DDD0DD,eolfilled,italics");     # Here-doc (back ticks, qx)
	$ed->StyleSetSpec(26,"fore:#7F007F,$(font.monospace),notbold");          # Single quoted string, generic 
	$ed->StyleSetSpec(27,"fore:#ee7b00,back:#fff8f8");                       # qq = Double quoted string
	$ed->StyleSetSpec(28,"fore:#ff7700,back:#f9f9d7");                       # qx = Back ticks
	$ed->StyleSetSpec(29,"fore:#000000,back:#A0FFA0");                       # qr = Regex
	$ed->StyleSetSpec(30,"fore:#f36600,back:#fff8f8");                       # qw = Array
}

sub set_highlight_yaml {
	my ($self) = @_;
	my $ed = $self->{'editor'};
	$ed->StyleClearAll;
	$ed->SetLexer( &Wx::wxSTC_LEX_YAML );
	$ed->SetKeyWords(0,'true false yes no');                                 # Add new keyword.
	$ed->StyleSetSpec( &Wx::wxSTC_H_TAG, "fore:#000055" );                   # Apply tag style for selected lexer (blue)
	$ed->StyleSetSpec(0,"fore:#000000");                                     # default
	$ed->StyleSetSpec(1,"fore:#008800");                                     # comment line
	$ed->StyleSetSpec(2,"fore:#000088,bold");                                # value identifier
	$ed->StyleSetSpec(3,"fore:#880088");                                     # keyword value
	$ed->StyleSetSpec(4,"fore:#880000");                                     # numerical value
	$ed->StyleSetSpec(5,"fore:#008888");                                     # reference/repeating value
	$ed->StyleSetSpec(6,"fore:#FFFFFF,bold,back:#000088,eolfilled");         # document delimiting line
	$ed->StyleSetSpec(7,"fore:#333366");                                     # text block marker
	$ed->StyleSetSpec(8,"fore:#FFFFFF,italics,bold,back:#FF0000,eolfilled"); # syntax error marker
}

sub set_highlight_tex {
	my ($self) = @_;
	my $ed = $self->{'editor'};
	$ed->StyleClearAll;

    my $tex_primitives = 'above abovedisplayshortskip abovedisplayskip
    abovewithdelims accent adjdemerits advance afterassignment
    aftergroup atop atopwithdelims
    badness baselineskip batchmode begingroup
    belowdisplayshortskip belowdisplayskip binoppenalty botmark
    box boxmaxdepth brokenpenalty
    catcode char chardef cleaders closein closeout clubpenalty
    copy count countdef cr crcr csname
    day deadcycles def defaulthyphenchar defaultskewchar
    delcode delimiter delimiterfactor delimeters
    delimitershortfall delimeters dimen dimendef discretionary
    displayindent displaylimits displaystyle
    displaywidowpenalty displaywidth divide
    doublehyphendemerits dp dump
    edef else emergencystretch end endcsname endgroup endinput
    endlinechar eqno errhelp errmessage errorcontextlines
    errorstopmode escapechar everycr everydisplay everyhbox
    everyjob everymath everypar everyvbox exhyphenpenalty
    expandafter
    fam fi finalhyphendemerits firstmark floatingpenalty font
    fontdimen fontname futurelet
    gdef global group globaldefs
    halign hangafter hangindent hbadness hbox hfil horizontal
    hfill horizontal hfilneg hfuzz hoffset holdinginserts hrule
    hsize hskip hss horizontal ht hyphenation hyphenchar
    hyphenpenalty hyphen
    if ifcase ifcat ifdim ifeof iffalse ifhbox ifhmode ifinner
    ifmmode ifnum ifodd iftrue ifvbox ifvmode ifvoid ifx
    ignorespaces immediate indent input inputlineno input
    insert insertpenalties interlinepenalty
    jobname
    kern
    language lastbox lastkern lastpenalty lastskip lccode 
    leaders left lefthyphenmin leftskip leqno let limits 
    linepenalty line lineskip lineskiplimit long looseness 
    lower lowercase 
    mag mark mathaccent mathbin mathchar mathchardef mathchoice 
    mathclose mathcode mathinner mathop mathopen mathord 
    mathpunct mathrel mathsurround maxdeadcycles maxdepth 
    meaning medmuskip message mkern month moveleft moveright 
    mskip multiply muskip muskipdef 
    newlinechar noalign noboundary noexpand noindent nolimits 
    nonscript scriptscript nonstopmode nulldelimiterspace 
    nullfont number 
    omit openin openout or outer output outputpenalty over 
    overfullrule overline overwithdelims 
    pagedepth pagefilllstretch pagefillstretch pagefilstretch 
    pagegoal pageshrink pagestretch pagetotal par parfillskip 
    parindent parshape parskip patterns pausing penalty 
    postdisplaypenalty predisplaypenalty predisplaysize 
    pretolerance prevdepth prevgraf 
    radical raise read relax relpenalty right righthyphenmin 
    rightskip romannumeral 
    scriptfont scriptscriptfont scriptscriptstyle scriptspace 
    scriptstyle scrollmode setbox setlanguage sfcode shipout 
    show showbox showboxbreadth showboxdepth showlists showthe 
    skewchar skip skipdef spacefactor spaceskip span special 
    splitbotmark splitfirstmark splitmaxdepth splittopskip 
    string 
    tabskip textfont textstyle the thickmuskip thinmuskip time 
    toks toksdef tolerance topmark topskip tracingcommands 
    tracinglostchars tracingmacros tracingonline tracingoutput 
    tracingpages tracingparagraphs tracingrestores tracingstats 
    uccode uchyph underline unhbox unhcopy unkern unpenalty 
    unskip unvbox unvcopy uppercase 
    vadjust valign vbadness vbox vcenter vfil vfill vfilneg 
    vfuzz voffset vrule vsize vskip vsplit vss vtop 
    wd widowpenalty write
    xdef xleaders xspaceskip
    year';

    my $etex_primitives = 'beginL beginR botmarks
    clubpenalties currentgrouplevel currentgrouptype
    currentifbranch currentiflevel currentiftype
    detokenize dimexpr displaywidowpenalties
    endL endR eTeXrevision eTeXversion everyeof
    firstmarks fontchardp fontcharht fontcharic fontcharwd
    glueexpr glueshrink glueshrinkorder gluestretch
    gluestretchorder gluetomu
    ifcsname ifdefined iffontchar interactionmode
    interactionmode interlinepenalties
    lastlinefit lastnodetype
    marks topmarks middle muexpr mutoglue
    numexpr
    pagediscards parshapedimen parshapeindent parshapelength
    predisplaydirection
    savinghyphcodes savingvdiscards scantokens showgroups
    showifs showtokens splitdiscards splitfirstmarks
    TeXXeTstate tracingassigns tracinggroups tracingifs
    tracingnesting tracingscantokens
    unexpanded unless
    widowpenalties';

    my $pdftex_primitives = 'pdfadjustspacing pdfannot pdfavoidoverfull
    pdfcatalog pdfcompresslevel
    pdfdecimaldigits pdfdest pdfdestmargin
    pdfendlink pdfendthread
    pdffontattr pdffontexpand pdffontname pdffontobjnum pdffontsize
    pdfhorigin
    pdfimageresolution pdfincludechars pdfinfo
    pdflastannot pdflastdemerits pdflastobj
    pdflastvbreakpenalty pdflastxform pdflastximage
    pdflastximagepages pdflastxpos pdflastypos
    pdflinesnapx pdflinesnapy pdflinkmargin pdfliteral
    pdfmapfile pdfmaxpenalty pdfminpenalty pdfmovechars
    pdfnames
    pdfobj pdfoptionpdfminorversion pdfoutline pdfoutput
    pdfpageattr pdfpageheight pdfpageresources pdfpagesattr
    pdfpagewidth pdfpkresolution pdfprotrudechars
    pdfrefobj pdfrefxform pdfrefximage
    pdfsavepos pdfsnaprefpoint pdfsnapx pdfsnapy pdfstartlink
    pdfstartthread
    pdftexrevision pdftexversion pdfthread pdfthreadmargin
    pdfuniqueresname
    pdfvorigin
    pdfxform pdfximage';

    my $omega_primitives = 'odelimiter omathaccent omathchar oradical omathchardef omathcode odelcode
    leftghost rightghost
    charwd charht chardp charit
    localleftbox localrightbox
    localinterlinepenalty localbrokenpenalty
    pagedir bodydir pardir textdir mathdir
    boxdir nextfakemath
    pagewidth pageheight pagerightoffset pagebottomoffset
    nullocp nullocplist ocp externalocp ocplist pushocplist popocplist clearocplists ocptracelevel
    addbeforeocplist addafterocplist removebeforeocplist removeafterocplist
    OmegaVersion
    InputTranslation OutputTranslation DefaultInputTranslation DefaultOutputTranslation
    noInputTranslation noOutputTranslation
    InputMode OutputMode DefaultInputMode DefaultOutputMode
    noInputMode noOutputMode noDefaultInputMode noDefaultOutputMode';


# only the macros that make sense:
    my $partial_tex_macros = 'TeX
    bgroup egroup endgraf space empty null
    newcount newdimen newskip newmuskip newbox newtoks newhelp newread newwrite newfam newlanguage newinsert newif
    maxdimen magstephalf magstep
    frenchspacing nonfrenchspacing normalbaselines obeylines obeyspaces raggedright ttraggedright
    thinspace negthinspace enspace enskip quad qquad
    smallskip medskip bigskip removelastskip topglue vglue hglue
    break nobreak allowbreak filbreak goodbreak smallbreak medbreak bigbreak
    line leftline rightline centerline rlap llap underbar strutbox strut
    cases matrix pmatrix bordermatrix eqalign displaylines eqalignno leqalignno
    pageno folio tracingall showhyphens fmtname fmtversion
    hphantom vphantom phantom smash';

    my $partial_etex_macros = 'eTeX
    newmarks grouptype interactionmode nodetype iftype
    tracingall loggingall tracingnone';


	$ed->SetLexer(&Wx::wxSTC_LEX_TEX);                            # Set Lexers to use
	$ed->SetKeyWords(0,$tex_primitives.$partial_tex_macros);
	# $ed->StyleSetSpec( &Wx::wxSTC_H_TAG, "fore:#000055" );

	$ed->StyleSetSpec(0,"fore:#202020");					# Default
	$ed->StyleSetSpec(1,"fore:#007f7f");					# Special
	$ed->StyleSetSpec(2,"fore:#7f0000)");					# Group
	$ed->StyleSetSpec(3,"fore:#7f7f00");					# Symbol
	$ed->StyleSetSpec(4,"fore:#007f00");					# Command
	$ed->StyleSetSpec(5,"fore:#000000");					# Text

	$ed->StyleSetSpec(34,"fore:#00007f");					# Identifiers
	$ed->StyleSetSpec(35,"fore:#7f007f");					# Identifiers
}

1;

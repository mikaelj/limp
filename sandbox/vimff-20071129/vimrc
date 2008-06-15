set ai
set lisp 
set expandtab
syntax on

map e :call Perly()<CR>
map <F12> :call Startlisp()<CR>
map gf :call LispGotoFunction()<CR>
map gh :call Lisphelpexpr()<CR>
imap <tab> <ESC>:call Lispcomplete()<CR>a
map t :tabn<CR>
map <C-t> :tabp<CR>

function Startlisp()
:newtab
:set shell=/usr/local/bin/sbcl\ --eval\ (load\"~/.vimff/vimff\")
:shell
endfunction

function Perly() 
perl << HEREDOC
use strict;
use IO::Socket;
my $err = 0;
my @win = VIM::Windows();
my @buf = VIM::Buffers();
my $w = $win[0];
my $b = $buf[0];
my @pos = $w->Cursor(); # returns (row, col) array
my $name = $b->Name();  # returns buffer name

if(!$name){
  print STDERR "ERROR: Not editing an file\n";
  return;
}
if(!$b){
  print STDERR "ERROR: Not in an current buffer\n";
  return;
}

#
# get lisp form
#

my @tmp = (); # form to be evaluated
my $ol = 0;
my $n = $pos[0];

# determine if we are evaluating an one-liner
my $line = $b->Get($pos[0]);
if($line !~ /^\s*$/){
  my $lcb = 0;
  my $rcb = 0;
  while($line =~ /\(/g){ $lcb++}
  while($line =~ /\)/g){ $rcb++}
  if($lcb eq $rcb){ # equal paranthes on one line = one-liner !
    $ol = 1;
    push @tmp, $line;
  }
}

if($ol == 0){
  # go back from current cursor and slurp until DEFUN is found
  while(1){
    my $line = $b->Get($n);
    push @tmp, $line;
    last if($line =~ /[dD][eE][fF][uU][nN]/ or
            $line =~ /[dD][eE][fF][mM][aA][cC]/ or
            $line =~ /[dD][eE][fF][pP][aA][cC]/ or
            $line =~ /[dD][eE][fF][iN][nN][eE]/);
    $n--;
    if($n < 0){ # we've missed DEF
      @tmp = ();
      last;
    }
  }
  @tmp = reverse @tmp;
}

if($#tmp == -1){
  print STDERR "ERROR: couldn't get form\n";
  $err = 1;
  return;
}

# continue looking for IN-PACKAGE
my $package = 0;
while(1){
  my $line = $b->Get($n);
  if($line =~ /[iI][nN]\-[pP][aA][cC][kK][aA][gG][eE]/){
    $package = $line;
    last;
  }
  $n--;
  last if($n < 0);
}

#$package =~ s/.*[iI][nN]\-[pP][aA][cC][kK][aA][gG][eE]\s*([^\s\(]+)[\s\)]*$/$1/;
$package =~ s/.*[iI][nN]\-[pP][aA][cC][kK][aA][gG][eE]\s*([^\s\(]+)[\s\)].*/$1/;

#
# give data to lisp listener
#

my $sock = new IO::Socket::INET(PeerAddr => 'localhost',
                                PeerPort => '9999',
                                Proto => 'tcp');
if(!$sock){
  print STDERR "ERROR: Can't open socket to lisp-server\n";
  return;
}

if($package){
print $sock "(in-package $package)\n";
}
foreach my $line (@tmp){
  print $sock "  $line\n";
}
close $sock;

HEREDOC
endfunction

function LispGotoFunction() 
perl << HEREDOC
use strict;
use IO::Socket;
my $err = 0;
my @win = VIM::Windows();
my @buf = VIM::Buffers();
my $w = $win[0];
my $b = $buf[0];
my @pos = $w->Cursor(); # returns (row, col) array
my $name = $b->Name();  # returns buffer name
my $line = $b->Get($pos[0]);
# replace this with proper vim-Get function instead
for(my $i = 0; $i < $pos[1]; $i++){
  $line =~ s/^.(.*)/$1/;
}
$line =~ s/(.*) .*/$1/;
#print "function={$line}\n";
my @tmp = `grep 'defun $line ' *.lisp`;
if($#tmp == 0){
  my $file = $tmp[0];
  chomp $file;
  $file =~ s/(.*):.*/$1/;
  #print "file: $file\n";
  VIM::DoCommand(":tabnew $file");
  VIM::DoCommand(":/defun $line ");
}
HEREDOC
endfunction

function Lisphelpexpr() 
perl << HEREDOC
use strict;
use IO::Socket;
my $err = 0;
my @win = VIM::Windows();
my @buf = VIM::Buffers();
my $w = $win[0];
my $b = $buf[0];
my @pos = $w->Cursor(); # returns (row, col) array
my $name = $b->Name();  # returns buffer name
my $line = $b->Get($pos[0]);
# replace this with proper vim-Get function instead
for(my $i = 0; $i < $pos[1]; $i++){
  $line =~ s/^.(.*)/$1/;
}
$line = lc($line);
$line =~ s/([\w_:\/\*\.-]*).*/$1/;
# call external help generator
`~/.vimff/vimff-help.pl $line`;
# show result of help generator
VIM::DoCommand(":tabnew /tmp/vimff-help.txt");
HEREDOC
endfunction

function Lispcomplete() 
perl << HEREDOC
use strict;
use IO::Socket;
my $err = 0;
my @win = VIM::Windows();
my @buf = VIM::Buffers();
my $w = $win[0];
my $b = $buf[0];
my @pos = $w->Cursor(); # returns (row, col) array
my $name = $b->Name();  # returns buffer name
my $line = $b->Get($pos[0]);
# split up string to prefix, completion, and suffix
my $s1 = $pos[1]; # end of completion word
my $s0;
for($s0 = $s1; $s0 >= 0; $s0--){
  my $c = substr($line, $s0, 1);
  last if($c !~ /[\w\d_-]/);
}
$s0++;
$s1++;
my $p0 = substr($line, 0, $s0);
my $p1 = substr($line, $s1);
my $wc = substr($line, $s0, $s1 - $s0);
# call symbol completion
my $wn = `~/.vimff/vimff-comp.pl $wc`;
my $x = length($wn) - length($wc);
# write back symbol completion suggestion
$b->Set($pos[0],"$p0$wn$p1");
if($x > 0){
  $w->Cursor(($pos[0], $pos[1]+$x));
}
HEREDOC
endfunction


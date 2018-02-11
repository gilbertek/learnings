# solver.p6
use v6;

# my $sudoku = '000000075000080094000500600010000200000900057006003040001000023080000006063240000';
#
# $sudoku = $sudoku.trans: '0' => ' ';
constant $separator = '+---+---+---+';

# Using subroutine
sub chunks(Str $s, Int $chars) {
  gather loop (my $idx = 0; $idx < $s.chars; $idx+= $chars) {
    take substr($s, $idx, $chars)
  }
}

sub MAIN($sudoku) {
  my $substitued = $sudoku.trans: '0' => ' ';

  for $substitued.comb(9) -> $line {
    say $separator if $++ %% 3;
    say '|', $line.comb(3).join('|'), '|';
  }
  say $separator;
}

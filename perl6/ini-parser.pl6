#!/usr/bin/env perl6

use v6;

class IniFile::Actions {
    method key($/)     { make $/.Str }
    method value($/)   { make $/.Str }
    method header($/)  { make $/[0].Str }
    method pair($/)    { make $<key>.made => $<value>.made }
    method block($/)   { make $<pair>.map({ .made }).hash }
    method section($/) { make $<header>.made => $<block>.made }
    method TOP($/)     {
      make {
            _ => $<block>.made,
            $<section>.map: { .made },
        }
    }
}

grammar IniFile {
    token ws      { \h* }
    rule pair     { <key>    '='   <value> \n+ }
    token key     { \w+ }
    regex value   { <!before \s> <-[\n;]>+ <!after \s> }
    # token pair    { <key> \h* '=' \h* <value> \n+ }
    token header  { '[' ( <-[ \[ \] \n ]>+ ) ']' \n+ }
    token comment { ';' \N*\n+ }
    token block   { [ <pair> | <comment> ]* }
    token section { <header> <block> }
    token TOP     { <block> <section>* }

    sub parse-ini(Str $input, :$rule = 'TOP') {
        my $m = IniFile.parse($input, :actions(IniFile::Actions), :$rule);
        unless $m {
          die "The input is not a valid INI file.";
        }
        return $m.made;
    }

    sub manual-parse-ini(Str $input) {
        my $m = IniFile.parse($input);
        unless $m {
          die "The input is not a valid INI file.";
        }

        sub block(Match $m) {
          my %result;
          for $<block><pair> -> $pair {
            %result{ $pair<key>.Str } = $pair<value>.Str;
          }
          return %result;
        }

        my %result;
        %result<_> = block($m);
        for $m<section> -> $section {
          %result{ $section<header>[0].Str } = block($section);
        }
        return %result;
    }
}



# say manual-parse-ini($ini).perl;
# say parse-ini($ini).perl;

$ini = q:to/EOI/;
key1=value1

[sectoken]
key2=value2
key3 = with spaces

; comment lines start with a semicolon, and are
; ignored by the parser

[section2]
more=stuff
EOI

multi sub MAIN('test') {
  use Test;

  ok 'abc'             ~~  /^ <key> $/,    '<key matches a simple identifier';
  ok '[abc]'          !~~ /^ <key> $/,    '<key> does not match a section header';
  ok "key=value\n"     ~~ /<pair>/,        'simple pair';
  ok "key = value\n\n" ~~ /<pair>/,        'pair with blanks';
  ok "key\n= value\n" !~~ /<pair>/,       'pair with newline before';
  ok "[abc]\n"         ~~ /^ <header> $/,  'simple header';
  ok "[a c]\n"         ~~ /^ <header> $/,  'header with spaces';
  ok "[a [b]]\n"      !~~ /^ <header> $/, 'cannot nest header';
  ok "[a\nb]\n"       !~~ /^ <header> $/, 'No newline inside header';
  ok $ini              ~~ /^<inifile>$/,   'Can parse a full INI file';

  is-deeply parse-ini("k = v\n", :rule<pair>), 'k' => 'v', 'can parse s simple pair';

  done-testing;
}

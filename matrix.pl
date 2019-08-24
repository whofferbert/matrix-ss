#!/usr/bin/env perl
# by William Hofferbert
# a terminal screen wasting utility
use strict;			# good form
use warnings;			# also good form
use 5.010;			# say
use Term::ANSIColor;		# colors
use Term::ReadKey;		# GetTerminalSize
use Term::Cap;			# Tgetent
use Time::HiRes qw(sleep time);
use Getopt::Long;		# opts

#
# env
#

my $min_bar_length   = 5;
my $max_bar_length   = 15;
my $sleep_secs       = 0.09;
my $bar_density_mod  = 14; # max possible num bars to make at once if we are short
my $bar_speed_mod    = 3;
my $speedmod_gov     = 7;  # (int(rand($speedmod_gov - $bar_speed_mod)) % $bar_speed_mod); = speedcontrol
my $max_percent_fill = 90; # limit on screen denisty

#
# setup
#

my %bars;
my %xy;
my @lines;
my @chars;

# get terminal conf and stuff
my $term = Term::Cap->Tgetent;
my $clear_string = $term->Tputs('cl');
my ($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();
my $screen_area = $wchar * $hchar;

# all the things from ANSIColor
my @txt_methods = qw(RESET RESET BOLD DARK);
my @fg_gr = qw(GREEN BRIGHT_GREEN RESET RESET);
my @fg_bl = qw(BLACK BRIGHT_BLACK RESET RESET);
my @bg_gr = qw(ON_GREEN ON_BRIGHT_GREEN RESET RESET);
my @bg_bl = qw(ON_BLACK ON_BRIGHT_BLACK RESET RESET);

# hacks
{
  no warnings; #what a jerk...
  @chars = qw(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 
  a b c d e f g h i j k l m n o p q r s t u v w x y z ` ~ ! @ # $ % ^ & * ( ) _ + - =
 \\ + [ { ] } | ; " ' : , < . > / ? );
}
my $chars_len = scalar(@chars);

# counting
my $bar_index = 0;

#
# subs
#

sub help {
  my $help = qq{
  A perl implementation of a hacker-kinda terminal screen saver/screen waster.

    Usage: $0 -[options]

  Options:

    sleep-secs|sleep|s [float]     Specify a float that is the value to sleep 
                                   between screen prints. Smaller numbers =
                                   faster falling text.
                                   Currently $sleep_secs

    help|h                         Print this help text

  };
  say $help;
  exit;

}

sub get_opts {
  GetOptions ("sleep-secs|sleep|s=f"     => \$sleep_secs,
              "help|h"                  => \&help)
  or die("Error in command line arguments\n");
}

sub rand_char {
  return $chars[int(rand($chars_len))];
}

sub rand_color {
  my ($fg_col, $bg_col);
  if (int(rand(10)) % 2) {
    $fg_col = $fg_gr[int(rand(scalar @fg_gr))];
    $bg_col = $bg_bl[int(rand(scalar @bg_bl))];
  } else {
    $fg_col = $fg_bl[int(rand(scalar @fg_bl))];
    $bg_col = $bg_gr[int(rand(scalar @bg_gr))];
  }
  return ($fg_col, $bg_col);
}

sub rand_txt_mthd {
  return $txt_methods[int(rand(scalar @txt_methods))];
}

sub cleanup {
  printf("%s", colored(" ", "$txt_methods[0]") );
  printf("%s", colored(" ", "$txt_methods[1]") );
  &clearscreen;
  exit;
}

sub clearscreen {
  print "$clear_string";
}

sub new_bar {
  my $bar_length = int(rand($max_bar_length - $min_bar_length)) + $min_bar_length;
  # avoid key collision
  $bar_index++;
  my $bar_num = $bar_index;
  $bars{$bar_num}{x} = int(rand($wchar));
  $bars{$bar_num}{y} = 0;
  $bars{$bar_num}{len} = $bar_length;
  # set up char sting, with colors
  my @barchars;
  for (0 .. $bar_length) { # same as HERE
    my $thing = &rand_char;
    my ($fg, $bg) = &rand_color;
    my $mthd = &rand_txt_mthd;
    push(@barchars, colored($thing, "$mthd $fg $bg"));
  }
  push(@barchars, colored(" ", "$txt_methods[1]")); # this space saves us from clearing the screen
  @{$bars{$bar_num}{barchars}} = @barchars;
}

sub new_bar_check {
  # calculate screen density
  my $num_bars = (keys %bars) + 0;
  my $avg_bar_len = ($max_bar_length + $min_bar_length) / 2;
  my $bar_area = $num_bars * $avg_bar_len;
  # add new bar if not too dense
  if (($bar_area / $screen_area) <= ($max_percent_fill / 100)) {
    for (1 .. int(rand($bar_density_mod))) {
      &new_bar;
    }
  }
}

sub mangle_bars {
  # this sub actually wasn't needed
  # thanks to all the terminal emulators
  # being as glitchy as they are... 
  # I wanted this to flip flop some chars
  # and colors. terminal takes care of that
  # for me. so lucky ... :/
}

sub advance_bars {
  foreach my $bar (keys(%bars)) {
    # variable speed control
    my $speedmod = (int(rand($speedmod_gov - $bar_speed_mod)) % $bar_speed_mod);
    if ( $speedmod > 0 ) {
      $bars{$bar}{y} = $bars{$bar}{y} + $speedmod;
    } else {
      $bars{$bar}{y}++;
    }
  }
}

sub bars_to_xy {
  %xy = (); # clear the xy hash;
  foreach my $bar (keys(%bars)) {
    my $x = $bars{$bar}{x};
    for my $i (0 .. $bars{$bar}{len}) { # same as HERE
      my $y = $bars{$bar}{y} - $i;
      $xy{$y}{$x} = $bars{$bar}{barchars}[$i];
    }
  }
}

sub remove_old_bars {
  foreach my $bar (keys(%bars)) {
    my $bar_depth = $bars{$bar}{y} - $bars{$bar}{len};
    if ($bar_depth > $hchar) {
      delete $bars{$bar};
    }
  }
}

sub build_screen {
  @lines = (); # clear lines array
  foreach my $y (0 .. $hchar - 2) {
    my $line = "";
    foreach my $x (0 .. $wchar - 1) {
      if (exists $xy{$y}{$x}) {
        $line = $line . $xy{$y}{$x};
      } else {
        $line = $line . " ";
      }
    }
    push(@lines, $line);
  }
}

sub print_screen {
  # reset cursor position
  print $term->Tgoto("cm", 0, 0); # 0-based
  foreach my $line (@lines) {
    say $line ; 
  }
}

sub display_screensaver {
  for (;;) {
    &new_bar_check;
    &mangle_bars;
    &bars_to_xy;
    &advance_bars;
    &remove_old_bars;
    &build_screen;
    &print_screen;
    sleep $sleep_secs;
  }
}

sub main {
  &get_opts;
  $SIG{INT} = "cleanup";
  &display_screensaver;
}


&main;


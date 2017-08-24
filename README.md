# matrix.pl

This perl script is a little thing that acts kind of like a screen saver or a screen waster.

Depending on your terminal settings, it may waste your buffer quickly.

It's nice, however, because it's just a CLI utility.

Requires the following to run:

Perl 5.010
Term::ANSIColor
Term::ReadKey
Term::Cap
Time::HiRes
Getopt::Long


```bash
$ ./matrix.pl -h

  A perl-y implementation of a hacker-kinda terminal screensaver/screenwaster.

    Usage: ./matrix.pl [options if desired]

  Options:

    sleep-secs|sleep|s [float]     Specify a float that is the value to sleep between character prints.
                                        Currently 0.1

    help|h                         Print this help text

```

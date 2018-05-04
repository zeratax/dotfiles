#!/usr/bin/perl
# https://serverfault.com/questions/373058/comparing-owners-and-permissions-of-content-of-two-folders/373071#373071

use File::Find;

my $directory1 = '/usr';
my $directory2 = '/run/media/motoko/backup/usr';

find(\&hashfiles, $directory1);

sub hashfiles {
  my $file1 = $File::Find::name;
  (my $file2 = $file1) =~ s/^$directory1/$directory2/;

  my $mode1 = (stat($file1))[2] ;
  my $mode2 = (stat($file2))[2] ;

  my $uid1 = (stat($file1))[4] ;
  my $uid2 = (stat($file2))[4] ;

  print "Permissions for $file1 and $file2 are not the same\n $directory1 = $mode1\n$directory2 = $mode2\n\n" if ( $mode1 != $mode2 );
  print "Ownership for $file1 and $file2 are not the same\n $directory = $uid1\n$directory2 = $uid2\n\n" if ( $uid1 != $uid2 );
}

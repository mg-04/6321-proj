#!/usr/bin/perl

# Found in the memory compiler user guide, could be useful
# Convert CDL to Spice
# Usage example: ./celtic.pl "MyMemInstName.cdl" "MyMemInstName_mod.cdl

if($#ARGV < 1) {
&showSyntax();
exit(-1);
}
$inp_file = $ARGV[0];
print $inp_file;
shift;
$out_file = $ARGV[0];
shift;

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Description : Show usage synatx
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sub showSyntax() {
print "Command line: $0 <input>.cdl <output>.cdl\n";
exit(-1);
}
open (INP_F, "< $inp_file") || die "Could not open
<input>.cdl";
open(OUT_F, "> $out_file") || die "FATAL : Fail to open file,
Exit.\n";
$i=0;
@inp_f = <INP_F>;
close(INP_F);

while ($i<=$#inp_f) {
#For M to XM
if ($inp_f[$i] =~ /^M/) {
$out_f= "X$inp_f[$i]";
print OUT_F "$out_f";
} elsif ($inp_f[$i] =~ /^D/) {
#For D to XD and adding Area and Perim
$j=0;
$out_f= "X$inp_f[$i]";
@varr = split(" ", $out_f);
while ($j<=$#varr) {
if(@varr[$j] =~ /[0-9][.][0-9]*e/) {
@varr[$j] = "Area=@varr[$j]";
} elsif(@varr[$j] =~ /[0-9][.][0-9]*/) {
@varr[$j] = "Perim=@varr[$j]";
}

print OUT_F "@varr[$j] ";
$j++;
}
print OUT_F "\n";
} else {
$out_f= "$inp_f[$i]";
print OUT_F "$out_f";
}
$i++;
}
close(OUT_F);
exit(1);

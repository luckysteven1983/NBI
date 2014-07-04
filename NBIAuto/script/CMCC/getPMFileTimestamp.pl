#!/bin/perl


use Time::Local;

sub timelocal_I{
# This subroutine transfter different date format to unix time for delay calculation.
my($timestring,$subtype)=@_;

# subtype=2 -> 200909081315
if($subtype==1){
   my ($year,$month,$day,$hour,$minutes) = unpack("A4"."A2"x5,$timestring);
   return timelocal(0,$minutes,$hour,$day,$month-1,$year-1900);
  } 

  
}


########################################################################################################################
# localtime_I($timgstring,$type)
########################################################################################################################
sub localtime_I{
# This subroutine used for date format transition.
@months{qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)} = (1..12);
my($input,$subtype)=@_;

#Wed Nov 14 10:30:00 2012 
if($subtype==1){
  if($input =~ /\w+\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)/){
      $mon = $months{$1};
      $format_string=sprintf "%04d%02d%02d-%02d%02d",$6,$mon,$2,$3,$4;
      return $format_string;
  } 
 }

}


$argsLen=@ARGV;
if( $argsLen ne 1)
{
   die "output file name needed, program exit. \n";
}

my $timefile=@ARGV[0];


@currentTime=localtime(time());
#Thu Nov 28 20:27:13 CST 2013
#@currentTime=qw /13 43 14 28 10 113 4 331 0/;
$currentMin=$currentTime[1];
$currentHour=$currentTime[2];
$currentDay=$currentTime[3];
$currentMon=$currentTime[4]+1;
$currentYear=$currentTime[5]+1900;

$no=sprintf "%d",$currentMin/15;

if($no=0) {
	@startTime=localtime(time()-7200);
  $startYear=$startTime[5]+1900;
	$startMon=$startTime[4]+1;
	$startDay=$startTime[3];
  $startHour=$startTime[2];
  $startMin=45;

	@stopTime=localtime(time()-3600);
  $stopYear=$stopTime[5]+1900;
	$stopMon=$stopTime[4]+1;
	$stopDay=$stopTime[3];
  $stopHour=$stopTime[2];
  $stopMin=45;
}
else{
	$no=sprintf "%d",$currentMin/15;
	@startTime=localtime(time()-3600);
  #@startTime=qw /13 43 13 28 10 113 4 331 0/;

  $startYear=$startTime[5]+1900;
	$startMon=$startTime[4]+1;
	$startDay=$startTime[3];
  $startHour=$startTime[2];
  $startMin=($no-1)*15;	
  
  $stopYear=$currentYear;
  $stopMon=$currentMon;
  $stopDay=$currentDay;
 	$stopHour=$currentHour;
	$stopMin=$startMin;
	
}	


if($startMin<10) {$startMin="0".$startMin;}
if($startHour<10) {$startHour="0".$startHour;}
if($startDay<10) {$startDay="0".$startDay;}
if($startMon<10) {$startMon="0".$startMon;}

if($stopMin<10) {$stopMin="0".$stopMin;}
if($stopHour<10) {$stopHour="0".$stopHour;}
if($stopDay<10) {$stopDay="0".$stopDay;}
if($stopMon<10) {$stopMon="0".$stopMon;}

$fromtime_str=$startYear.$startMon.$startDay.$startHour.$startMin;
$endtime_str=$stopYear.$stopMon.$stopDay.$stopHour.$stopMin;

$fromTime=timelocal_I($fromtime_str,1);
$endTime=timelocal_I($endtime_str,1);

open(timelist,">$timefile") || die "$!";

$N_EndSecond=$fromTime;
while($N_EndSecond < $endTime)
{
	 $print_time_U=localtime($N_EndSecond);
   $print_str=localtime_I($print_time_U,1);
   @printTime=localtime($N_EndSecond);
   $printMin=$printTime[1];
   if($printMin<10) {$printMin="0".$printMin;}
   print timelist "$print_str\t$printMin\n";
   
   $N_EndSecond+=900;
	
}

close(timelist);


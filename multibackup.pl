#!/usr/bin/perl

use strict;
use warnings;

# Set these for your situation
my $MTDIR = "/home/mtowner/MultiCraft2";
my $BACKUPDIR = "/home/mtowner/backups";
my $TARCMD = "/bin/tar czf";
my $BACKUP_DELAY = 5;
my $DOING_DELAY = "false";
my $BACKUP_CONFIG = "/home/mtowner/MultiBackup/backups.rc";
my $DEBUG_MODE = "false";	# Set to "true" to enable debug output

#-------------------
# No changes below here...
#-------------------
my $VERSION = "1.5";

my $WarnMessage = "Warning - the multicraft game is about to run a backup. You have $BACKUP_DELAY minutes to finish saving your changes.\n";
my $BackupStartMessage = "========== Backup is starting. Please do not try and log in till it is complete.";
my $BackupDoneMessage = "========== The backup has finished and you may now log in within 1 minute.";

sub debugPrint
{
	if ($DEBUG_MODE eq "true")
	{
		print "$_[0]";
	}
}

# Check if there is a file of settings
if (-f $BACKUP_CONFIG)
{
	# Yes, so read it in
	if (open(my $fh, '<:encoding(UTF-8)', $BACKUP_CONFIG))
	{
		# Loop for each line in the file
		while (my $row = <$fh>)
		{
			chomp $row;
			my $CommentChar = substr($row, 0, 1);
			if ($CommentChar eq "#")
			{
				next;
			}
			(my $command, my $setting) = split(/=/, $row);
			if ($command eq "BACKUP_DELAY")
			{
				debugPrint("Saw command $command\n");
				$BACKUP_DELAY = $setting;
			}
			elsif ($command eq "BACKUP_CONFIG")
			{
				debugPrint("Saw command $command\n");
				$BACKUP_CONFIG = $setting;
			}
			else
			{
				die ("Unknown command: $command\n");
			}
		}
		close($fh);
	}
	else
	{
		warn "Could not open file '$BACKUP_CONFIG' $!";
	}
}

sub DoWarn
{
	# Send out our message
	system("echo \"$WarnMessage\" | nc localhost 3461");

	print "Doing a delay of $BACKUP_DELAY minutes\n";
	sleep($BACKUP_DELAY * 60);
	system("echo \"$BackupStartMessage\" | nc localhost 3461");
}

if ($ARGV[0] eq "warn")
{
	$DOING_DELAY = "true";
}

print "MultiBackup.pl version $VERSION\n";
print "=========================\n";

if ($DOING_DELAY eq "true")
{
	DoWarn();
}

if (! -d $BACKUPDIR)
{
	print "Backup dir $BACKUPDIR not found, creating...\n";
	system("mkdir -p $BACKUPDIR");
}
print "Moving existing backups: ";

if (-f "$BACKUPDIR/multibackup-5.tgz")
{
	unlink("$BACKUPDIR/multibackup-5.tgz")  or warn "Could not unlink $BACKUPDIR/multibackup-5.tgz: $!";
}
if (-f "$BACKUPDIR/multibackup-4.tgz")
{
	rename("$BACKUPDIR/multibackup-4.tgz", "$BACKUPDIR/multibackup-5.tgz");
}
if (-f "$BACKUPDIR/multibackup-3.tgz")
{
	rename("$BACKUPDIR/multibackup-3.tgz", "$BACKUPDIR/multibackup-4.tgz");
}
if (-f "$BACKUPDIR/multibackup-2.tgz")
{
	rename("$BACKUPDIR/multibackup-2.tgz", "$BACKUPDIR/multibackup-3.tgz");
}
if (-f "$BACKUPDIR/multibackup-1.tgz")
{
	rename("$BACKUPDIR/multibackup-1.tgz", "$BACKUPDIR/multibackup-2.tgz");
}
print "Done\nCreating New Backup: ";
# set no respawn
system("touch '$MTDIR/nostart'");

my $running=`ps ax|grep multicraftserver|grep -v grep`;

if ($running ne "")
{
	# Process is running, kill it
	system("killall multicraftserver");
	sleep(20);
}
system("$TARCMD $BACKUPDIR/multibackup-1.tgz $MTDIR");
print("Done!\n");
# Remove respawn flag
if (-f "$MTDIR/nostart")
{
	print "Removing $MTDIR/nostart\n";
	# Remove the lock file if it exists
	unlink("$MTDIR/nostart");
}
print("Server should restart within 60 seconds!\n");
if ($DOING_DELAY eq "true")
{
	system("echo \"$BackupDoneMessage\" | nc localhost 3461");
}
sleep(5);
exit 0;

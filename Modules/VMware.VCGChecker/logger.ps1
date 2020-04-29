<#
Copyright 2018 VMware, Inc.  All rights reserved.

#>

# Messages
$HEADER_OK = "[OK]  "
$HEADER_INFO = "[INFO]  "
$HEADER_WARNING = "[WARNING]  "
$HEADER_ERR = "[ERROR]  "

Class DebugLog
{
    # Static variables of the logger class
    static [string] $CAFILE_PATH = "./.certs/"

    [boolean] $debug
    [string] $logfile

    DebugLog()
    {
        $this.debug = $false
        $this.logfile = $null
        if (!(Test-Path $this::CAFILE_PATH))
	    {
		    New-Item -Type directory -Confirm:$false -Path $this::CAFILE_PATH
	    }
    }

    [void] SetDebug(
        [boolean] $debug,
        [string] $hostname
    ){
        if (!$hostname) {$hostname = ''}
        $this.debug = $debug
        if ($this.debug)
        {
            $this.logfile = $this::CAFILE_PATH + $hostname + [DateTime]::Now.ToString("_yyyy-MM-dd_HH-mm") + ".log"
        }else{
            $this.logfile = $null
        }
    }

    [void] log_vars(
        [string] $message,
        [object] $var
    ){
        $this.log($message + $var)
    }

    [void] log(
        [string] $message
    ){
        if (!$this.debug -or !$this.logfile) {return}
        try
        {
            $message | Out-File $this.logfile -Append
        }catch {
            Out-Host -InputObject ("[Exception] Failed to write to a logfile: " + $this.logfile)
            Out-Host -InputObject $_
        }
    }
}

Function debug_vars(
    [string] $message,
    [object] $var)
{
    $logger.log_vars($message, $var)
}

Function debug(
    [string] $message)
{
    $logger.log($message)
}

Function vcglog(
    [string] $message,
    [string] $header="")
{
    $msg = $header + $message
    $logger.log($msg)
    Out-Host -InputObject $msg
}

Function ok(
    [string] $message)
{
    vcglog $message $HEADER_OK
}

Function warning(
    [string] $message)
{
    vcglog $message $HEADER_WARNING
}

Function info(
    [string] $message)
{
    vcglog $message $HEADER_INFO
}

Function error(
    [string] $message)
{
    vcglog $message $HEADER_ERR
}

$logger = [DebugLog]::new()
$logger.SetDebug($true, "vcc-debug")
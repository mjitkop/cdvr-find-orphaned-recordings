# cdvr-find-orphaned-recordings
Get a list of recordings present on disk(s) but unknown to a Channels DVR server.

## Python script

### Prerequisites

Make sure Python is installed on your computer. See https://www.python.org/downloads/

### Usage

The script may take two optional input arguments: `--ip IP_ADDRESS` and `--port PORT_NUMBER`

If not provided, the default IP address is `127.0.0.1`, and the default port number is `8089`.

The script may be called without arguments so the default values will be used:
> python cdvr_find_orphaned_recordings.py

Examples with arguments:
> python cdvr_find_orphaned_recordings.py --ip 192.168.18.75

> python cdvr_find_orphaned_recordings.py --port 8090

> python cdvr_find_orphaned_recordings.py --ip 192.168.18.75 --port 8090

## PowerShell script

### Prerequisites

#### Step 1 — Run this in PowerShell (NOT CMD)

Make sure your prompt starts with `PS`:
> PS C:\Users\mjitk>

#### Step 2 — Allow scripts for your user account

Run this command:
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

### Usage

The script may take two optional input arguments: `-Ip IP_ADDRESS` and `-Port PORT_NUMBER`

If not provided, the default IP address is `127.0.0.1`, and the default port number is `8089`.

The script may be called without arguments so the default values will be used:
> .\cdvr_find_orphaned_recordings.ps1

Examples with arguments:
> .\cdvr_find_orphaned_recordings.ps1 -Ip 192.168.18.75

> .\cdvr_find_orphaned_recordings.ps1 -Port 8090

> .\cdvr_find_orphaned_recordings.ps1 -Ip 192.168.18.75 -Port 8090

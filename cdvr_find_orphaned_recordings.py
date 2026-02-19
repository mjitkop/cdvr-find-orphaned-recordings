"""
Author: Gildas Lefur (a.k.a. "mjitkop" in the Channels DVR forums)

Description: This script connects to a Channels DVR instance, retrieves the list of recording paths from the DVR database, 
             checks the storage paths for video files, and identifies any "orphaned" recordings (video files that exist 
             on disk but are not listed in the DVR database). The script then prints a list of these orphaned recordings.

Disclaimer: this is an unofficial script that is NOT supported by the developers of Channels DVR.

Version History:
- 1.0.0: Initial public release.
"""

#===============================================================================
#                                   IMPORTS
#===============================================================================

import argparse
import os
import requests
import sys

#===============================================================================
#                                   FUNCTIONS
#===============================================================================

def get_storage_paths(dvr_url):
    '''Fetches recording paths from Channels DVR API.'''
    print("\nFetching storage paths from the server...")
    paths = []
    try:
        response = requests.get(f"{dvr_url}/dvr")
        response.raise_for_status()
        json_data = response.json()

        paths.append(json_data.get("path"))
        paths.extend(json_data.get("extra_paths"))

    except requests.RequestException as e:
        print(f"Error fetching recording paths: {e}")
        sys.exit(1)

    print(f" -> Retrieved storage paths: {paths}")
    return paths

def get_recording_paths(dvr_url):
    '''Fetches paths of all recordings from Channels DVR database.'''
    print("\nFetching recording paths from the server...")
    paths = []
    try:
        response = requests.get(f"{dvr_url}/api/v1/all")
        response.raise_for_status()
        recordings = response.json()

        for recording in recordings:
            paths.append(recording.get("path"))

    except requests.RequestException as e:
        print(f"Error fetching recording paths: {e}")
        sys.exit(1)

    print(f" -> Retrieved {len(paths)} recording paths from the server.")
    return paths

def get_files_on_disks(storage_paths):
    '''Checks storage paths for files and returns a list of file paths.'''
    print("\nChecking storage paths for files...")
    files = []
    for path in storage_paths:
        for directory in os.listdir(path):
            if directory in ["Movies", "TV"]:
                dvr_directory = os.path.join(path, directory)
                recordings = os.listdir(dvr_directory)
                print(f" -> Found {len(recordings)} files in {dvr_directory}")
                for recording in recordings:
                    file_path = os.path.join(dvr_directory, recording)
                    if os.path.isfile(file_path):
                        files.append(file_path)

    print(f"-> Found a total of {len(files)} files on disks.")
    return files

def is_video_file(filename):
    '''Checks if a file is a video based on its extension.'''
    video_extensions = [".mp4", ".mpg", ".mkv", ".avi", ".mov", ".ts"]
    return any(filename.lower().endswith(ext) for ext in video_extensions)

#===============================================================================
#                                 MAIN PROGRAM
#===============================================================================

def main():
    parser = argparse.ArgumentParser(description="Find orphaned recordings in Channels DVR.")
    parser.add_argument("--ip", default="127.0.0.1", help="IP address of Channels DVR (default: 127.0.0.1)")
    parser.add_argument("--port", default="8089", help="Port number of Channels DVR (default: 8089)")
    args = parser.parse_args()
    
    dvr_url = f"http://{args.ip}:{args.port}"
    print(f"Using Channels DVR at: {dvr_url}")
    
    recording_paths = get_recording_paths(dvr_url)

    storage_paths = get_storage_paths(dvr_url)
    files_on_disks = get_files_on_disks(storage_paths)

    orphaned_recordings = []
    for file_on_disk in files_on_disks:
        if is_video_file(file_on_disk) and file_on_disk not in recording_paths:
            orphaned_recordings.append(file_on_disk)

    if orphaned_recordings:
        print(f"\nFound {len(orphaned_recordings)} orphaned recordings:")
        for recording in orphaned_recordings:
            print(f" -> {recording}")
    else:
        print("\nNo orphaned recordings found.")

if __name__ == "__main__":
    main()

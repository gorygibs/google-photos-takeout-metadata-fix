# 🤖 Google Photos Takeout Metadata Restoration Script

**A note on this Script and Readme:** An agent (a Large Language Model from OpenAI) helped write this script. An agent (a Large Language Model from Google) was used to write this documentation.

**`Invoke-GPhotosMetadataFix.ps1`** is a powerful PowerShell script designed to fix the chronic metadata issues resulting from a Google Takeout export of your Google Photos library.

This script uses the robust **ExifTool** utility to read creation dates, descriptions, and GPS coordinates from the separate `.json` "sidecar" files and embed that correct metadata back into your corresponding image (`.jpg`, `.png`) and video (`.mp4`, `.mov`) files.

-----

## ⚠️ WARNING: Always Back Up Your Data\!

This script directly modifies your original photo and video files. Before running it, **you MUST create a full backup** of your Google Takeout directory. The script is designed to overwrite the original files with the corrected metadata. Proceed at your own risk.

-----

## 🚀 Key Features

This solution was developed with the assistance of an LLM (Large Language Model) to specifically address the inconsistencies found in Google Takeout archives:

  * **Intelligent File Matching:** Correctly matches media files with their corresponding JSON files, even if the files have suffixes like `(1)`, `-edited`, or `-cropped`.
  * **Full Date Restoration:** Prioritizes the `photoTakenTime` from the JSON to restore the true creation date of the media.
  * **Video Support:** Correctly writes date and description tags for video files (`.mp4`, `.mov`) using the QuickTime and Track metadata fields.
  * **Location and Description:** Restores both GPS coordinates (Latitude/Longitude) and any user-added descriptions/captions.
  * **Fallback Logic (Enhanced):** Attempts to parse dates directly from common timestamp-based filenames if the JSON file is missing or corrupted. **The script now correctly recognizes dates separated by an underscore (`_`) in filenames (e.g., `YYYYMMDD_HHMMSS`) and uses an unambiguous date format for successful parsing.**

-----

## 🔧 Prerequisites

1.  **PowerShell:** This script requires PowerShell 5.1 or later (standard on most modern Windows systems).
2.  **ExifTool:** The script relies entirely on [Phil Harvey's ExifTool](https://exiftool.org/) for metadata manipulation.
      * You must download the Windows executable (`exiftool.exe`) and place it in a stable location.

-----

## 📝 Usage

To run the script, you must define the paths for your photo directory and the ExifTool executable within the `.ps1` file itself.

### Step 1: Download and Modify the Script

1.  Download the **`Invoke-GPhotosMetadataFix.ps1`** file.
2.  Open the file in a text editor (like VS Code, Notepad++, or Windows PowerShell ISE).
3.  Locate the `param` block at the very top of the script:

```powershell
param (
    [string]$PhotoRoot = "D:\Downloads\Takeout\Google Photos\Photos from 2020\New folder",
    [string]$ExifToolPath = "D:\Applications\exiftool\exiftool.exe"
)
````

### Step 2: Set the Photo Root Directory

Change the value for the **`$PhotoRoot`** parameter to the path of the folder containing your Google Photos Takeout files. The script is **recursive**, meaning it will process all subfolders within this path.

| Original Example | Your Required Change |
| :--- | :--- |
| `[string]$PhotoRoot = "D:\Downloads\Takeout\Google Photos\Photos from 2020\New folder"` | `[string]$PhotoRoot = "C:\Users\YourName\Desktop\MyTakeout\Google Photos"` |

### Step 3: Set the ExifTool Path

Change the value for the **`$ExifToolPath`** parameter to the exact location of the `exiftool.exe` file you downloaded.

| Original Example | Your Required Change |
| :--- | :--- |
| `[string]$ExifToolPath = "D:\Applications\exiftool\exiftool.exe"` | `[string]$ExifToolPath = "C:\Tools\ExifTool\exiftool.exe"` |

### Step 4: Execute the Script

You can run the script using either **PowerShell** or **Command Prompt (CMD)**.

#### **Option A: Running via PowerShell**

1.  Open **PowerShell** (search for it in the Start Menu).
2.  Navigate to the directory where you saved the **`Invoke-GPhotosMetadataFix.ps1`** script:
    ```powershell
    cd C:\path\to\your\script\
    ```
3.  Run the script:
    ```powershell
    .\Invoke-GPhotosMetadataFix.ps1
    ```

#### **Option B: Running via Command Prompt (CMD)**

1.  Open **Command Prompt (CMD)**.
2.  Run the script using the following command structure. Make sure to update the path to the script file:
    ```cmd
    powershell -ExecutionPolicy Bypass -File D:\Applications\exiftool\Invoke-GPhotosMetadataFix.ps1
    ```

The script will begin recursively scanning the photo root directory and display the actions it performs on each file, including any restored dates or GPS coordinates.

-----

## Tags Written to Media

The script writes the following metadata tags based on the file type:

| Data Type | Image Files (.jpg, .png) | Video Files (.mp4, .mov) |
| :--- | :--- | :--- |
| **Date/Time** | `EXIF:DateTimeOriginal`, `EXIF:CreateDate`, `EXIF:ModifyDate`, `XMP:CreateDate`, `XMP:DateCreated` | `QuickTime:CreateDate`, `QuickTime:ModifyDate`, `TrackCreateDate`, `TrackModifyDate`, `MediaCreateDate`, `MediaModifyDate` |
| **Description** | `ImageDescription`, `XMP:Description` | `XMP:Description`, `QuickTime:Comment` |
| **GPS** | `EXIF:GPSLatitude`, `EXIF:GPSLongitude`, `EXIF:GPSAltitude` | `EXIF:GPSLatitude`, `EXIF:GPSLongitude`, `EXIF:GPSAltitude` |

```
```

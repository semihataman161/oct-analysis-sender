Unit BasicLogger;

Interface

uses
  Windows, Messages, Variants, Classes, Graphics, Controls, Forms, SysUtils,
  System.Net.HttpClient,System.JSON, Rest.JSON, System.IOUtils, RegularExpressions,
  StdCtrls, ExtCtrls, jpeg, ApiWrapper, System.SyncObjs;

const
  EC_001 = 'EC-001';
  EC_101 = 'EC-101';
  EC_102 = 'EC-102';
  EC_103 = 'EC-103';
  EC_104 = 'EC-104';
  EC_105 = 'EC-105';
  EC_201 = 'EC-201';
  EC_202 = 'EC-202';
  EC_203 = 'EC-203';
  EC_301 = 'EC-301';
  EC_302 = 'EC-302';
  EC_400 = 'EC-400';
  EC_401 = 'EC-401';
  EC_402 = 'EC-402';
  EC_403 = 'EC-403';
  EC_404 = 'EC-404';
  DEBUG = 10;
  INFO = 20;
  WARN = 30;
  ERROR = 40;

  {
  RC_001 = 1;
  RC_101 = 101;
  RC_102 = 102;
  RC_103 = 103;
  RC_104 = 104;
  RC_105 = 105;
  RC_201 = 201;
  RC_202 = 202;
  RC_203 = 203;
  RC_301 = 301;
  RC_302 = 302;
  RC_401 = 401;
  RC_402 = 402;
  RC_403 = 403;
                          }


resourcestring
  RA_001 = 'Contact Customer Support for assistance.';
  RA_101 = '1. Check your computer''s internet connection.' + sLineBreak +
  '2. Ensure that either your computer firewall or a proxy is not blocking communication through port 443.' + sLineBreak +
  '3. If the problem persists, get support from your system administrator.';
  RA_102 = '1. Check your local internet connection.' + sLineBreak +
  '2. Check the size of the image file.' + sLineBreak +
  '3. Wait and try again later.';
  RA_103 = 'The patient image/images have been deleted or corrupted. Check the image input directory to ensure that the patient images exist and are not corrupted.';
  RA_104 = 'The local Service is not running properly. Ensure that the "Service" is running on Windows Services Manager.';
  RA_105 = '1. There is a problem with the database connection.' + sLineBreak + '2. Ensure that the "mysql51" service is running on Windows Services Manager.' + sLineBreak +
  '3. Ensure that you are using the current database.' + sLineBreak +
  '4. Contact Customer Support for assistance.';
  RA_201 = '1. Go to the installation location.' + sLineBreak +
  '2. Verify the read/write permissions in the installation directory and corresponding subdirectories/files.' + sLineBreak +
  '3. Verify that there is sufficient disk space on the drive/partition where is installed.';
  RA_202 = 'Check the permissions in the selected manual and automatic save directories.';
  RA_203 = '1. There was a problem uploading the image. ' + sLineBreak +
  '2. Please check the size and extension of the image.' + sLineBreak +
  '3. Try uploading the image again.';
  RA_301 = 'Try downloading the update again.';
  RA_302 = 'Check the file location and contents and try again.';
  RA_400 = '1. Please ensure that your activation key is valid.' + sLineBreak +
  '2. If the problem persists, get support from your system administrator.';
  RA_401 = 'The client verifies whether the images are Optic Disc-centered (ODC) or Fovea-centered (FC) and rejects unidentified images.';
  RA_402 = 'The client checks the image quality and rejects unacceptable images.';
  RA_403 = 'The client automatically identifies the right and left Optic Disc-centered (ODC) or Fovea-centered (FC) and displays them in designated slots on the screen.';
  RA_404 = '1. Check your computer''s internet connection.' + sLineBreak +
  '2. Ensure that either your computer firewall or a proxy is not blocking communication through port 443.' + sLineBreak +
  '3. Ensure that wkhtmltopdf.exe and wkhtmltox.dll files are located in the C:\App folder.' + sLineBreak +
  '4. If the problem persists, get support from your system administrator.';
    // https://docs.google.com/spreadsheets/d/1N_JAVIeQFacAzsqaTePyl5G47ZR610QVnUcQ9Fs9G1w/edit#gid=0

function GetProgramDir(): String;
function GetPathTo(RelativePath: String): String;
procedure ErrorLog(pText: String);  overload;
procedure ErrorLog(pLogFileName: String; pValues: array of string); overload;
procedure WriteToRelativeFile(pFileName: String; pText: String);
procedure WriteToAbsoluteFile(pFilePath: String; pText: String);
function GetReccomendation(recCode:Integer):String;

Implementation

uses Dialogs,System.TypInfo;

var
  WriteToFileLock: TCriticalSection;
  ErrorLogLock: TCriticalSection;
  ErrorLogOverloadedLock: TCriticalSection;

function GetProgramDir(): String;
begin
  Result := ExtractFileDir(ParamStr(0));
end;

function GetPathTo(RelativePath: String): String;
begin
  Result := GetProgramDir() + '\' + RelativePath;
  Result := StringReplace(Result, '/', '\', [rfReplaceAll]); //convert forward slashes to backslashes
  Result := TRegEx.Replace(Result, '\\+', '\'); //singularize multiple backslashes
end;

procedure ErrorLog(pText: String);
Var
 logFile: TextFile;
begin
  ErrorLogLock.Enter;
  try
    try
      var filePath := GetPathTo('error.log');
      AssignFile(logFile, filePath);
      If FileExists(filePath) Then
        Append(logFile)
      Else
        Rewrite(logFile);
      Writeln(logFile, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now()) +' ['+ExtractFileName(Application.ExeName)+']['+IntToStr(GetCurrentThreadId)+'] ' + pText);
      CloseFile(logFile);
    Except
      on E: Exception do ErrorLog('ErrorLog Error: ' + E.Message);
    end;
  finally
    ErrorLogLock.Leave;
  end;
end;

procedure ErrorLog(pLogFileName: String; pValues: array of String);
var
 logFile: TextFile;
begin
  ErrorLogOverloadedLock.Enter;
  try
    try
      var filePath := GetPathTo(pLogFileName);
      AssignFile(logFile, filePath);

      if FileExists(filePath) then Append(logFile) else Rewrite(logFile);

      for var i := 0 to High(pValues) do
      begin
        Writeln(logFile, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now()) + ' ['+ExtractFileName(Application.ExeName)+']['+IntToStr(GetCurrentThreadId)+'] ' + pValues[i]);
      end;

      CloseFile(logFile);
    except
      on E: Exception do ErrorLog('ErrorLog Error: ' + E.Message);
    end;
  finally
    ErrorLogOverloadedLock.Leave;
  end;
end;

procedure WriteToRelativeFile(pFileName: String; pText: String);
begin
  WriteToAbsoluteFile(GetPathTo(pFileName), pText);
end;

procedure WriteToAbsoluteFile(pFilePath: String; pText: String);
var
  StreamWriter: TStreamWriter;
begin
  WriteToFileLock.Enter;
  try
    try
      // Specify the encoding when creating the TStreamWriter
      StreamWriter := TStreamWriter.Create(pFilePath, False, TEncoding.UTF8); // Use the appropriate encoding
      try
        StreamWriter.Write(pText);
      finally
        StreamWriter.Free;
      end;
    except
      on E: Exception do ErrorLog('WriteToFilePath Error: ' + E.Message);
    end;
  finally
    WriteToFileLock.Leave;
  end;
end;

function GetReccomendation(recCode:Integer):String;
var
ResString: PChar;
begin
  ResString := PChar(LoadStr(1));
  Result := string(ResString);
end;

initialization
  WriteToFileLock := TCriticalSection.Create;
  ErrorLogLock := TCriticalSection.Create;
  ErrorLogOverloadedLock := TCriticalSection.Create;

finalization
  WriteToFileLock.Free;
  ErrorLogLock.Free;
  ErrorLogOverloadedLock.Free;

end.


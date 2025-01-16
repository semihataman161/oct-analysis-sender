unit utilFile;

interface

Uses

Windows, Vcl.Dialogs, System.Json, System.IOUtils;

function GetFileSizeInt64(const FileName: String): Int64;

function CopyFileDir(const fromDir, toDir: string): Boolean;
function MoveFileDir(const fromDir, toDir: string): Boolean;
function CopyFileWithArbitraryName(const sourcePath, destinationDir, destinationFileName: string): Boolean;

{
  OverlapDirectory Operation Summary:
  fromDir  C:\a
             -> x
                -> a.txt
  toDir    C:\b
             -> x
                -> xsub
                -> b.txt
  final    C:\b
             -> x
                -> xsub
                -> a.txt
                -> b.txt
  note that C:\a (fromDir) deleted at the end..
  note that function does NOT create toDir if it does not exist.
}
function OverlapDirectory(const fromDir, toDir: string): Boolean;
function DelTree(DirName: string): Boolean;
function DeleteFileAndEmptyFolder(const FileName, StopFolder: String): Boolean;

procedure CleanupFiles(Dir: String; FilesBefore: TDateTime);

function DateTimeToFileName(ADateTime: TDateTime): String;

function BuildPath(const Paths: Array of String): String;


function ReadFileString(const FileName: String; var FileText: String): Integer;
function WriteFileString(const FileName, FileText: String): Integer;

// Added by Rym: Open built-in Windows select folder dialog
function GetFolderDialog(Handle: Integer; Caption: string; var strFolder: string): Boolean;

function getLastErrorString(LastError: Cardinal): String;
function getLastErrorStringEx: String;

function RunFileShellExecuteSimple(Handle: HWND; FileName: String): boolean;
function ReadFileContentAsJsonValue(fileName: String): TJSONValue;

const PATHNAME_FORBIDDEN_CHARS = [';', '*', '?', '"', '<', '>', '|'];
const PATHNAME_SPECIAL_CHARS = ['\', '/', ':'];
const FILENAME_FORBIDDEN_CHARS = PATHNAME_FORBIDDEN_CHARS + PATHNAME_SPECIAL_CHARS;


implementation

uses SysUtils, ShellAPI, SHFolder, IdGlobal, ShlObj, BasicLogger;

function GetFileSizeInt64(const FileName: String): Int64;
var Size: Int64Rec; hFile: THandle;
begin
  hFile := CreateFile(PChar(FileName), GENERIC_READ,
    FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE,
    nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if hFile = INVALID_HANDLE_VALUE then
    Result := 0
  else
    try
      Size.Lo := GetFileSize(hFile, @Size.Hi);
      Result := Int64(Size);
    finally
      CloseHandle(hFile);
    end;

{ Alternative using Indy 9 - functions
begin
  Result := FileSizeByName(FileName);
}
end;


function ReadFileString(const FileName: String; var FileText: String): Integer;
var
  hFile: Cardinal;
  NumberOfBytesRead: Cardinal;
begin
  hFile := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ,
             nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if hFile = INVALID_HANDLE_VALUE then
  begin
    FileText := '';
    Result := hFile;
  end
  else
  begin
    SetLength(FileText, MAX_PATH);
    ReadFile(hFile, FileText[1], Length(FileText), NumberOfBytesRead, nil);
    SetLength(FileText, NumberOfBytesRead);
    CloseHandle(hFile);
    Result := 0;
  end;
end;

function WriteFileString(const FileName, FileText: String): Integer;
var
  hFile: Cardinal;
  NumberOfBytesWritten: Cardinal;
begin
  hFile := CreateFile(PChar(FileName), GENERIC_WRITE, 0,
              nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if hFile = INVALID_HANDLE_VALUE then
    Result := hFile
  else
  begin
    WriteFile(hFile, FileText[1], Length(FileText), NumberOfBytesWritten, nil);
    CloseHandle(hFile);
    Result := 0;
  end;
end;

function DateTimeToFileName(ADateTime: TDateTime): String;
const DATETIMEFMT_FILENAME              = 'yyyy-mm-dd hhnnss';
begin
  Result := FormatDateTime(DATETIMEFMT_FILENAME, ADateTime);
end;

function BuildPath(const Paths: Array of String): String;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(Paths) do
  begin
    Result := Result + Paths[i];
    Result := IncludeTrailingPathDelimiter(Result);
  end;
  Result := ExcludeTrailingPathDelimiter(Result);
end;

function CopyFileDir(const fromDir, toDir: string): Boolean;
var
  fos: TSHFileOpStruct;
begin
  try
    ZeroMemory(@fos, SizeOf(fos));
    with fos do
    begin
      wFunc  := FO_COPY;
      pFrom  := PChar(fromDir + #0);
      pTo    := PChar(toDir + #0);
      fFlags := FOF_NOCONFIRMATION or FOF_NOERRORUI or FOF_SILENT or FOF_NOCONFIRMMKDIR;
    end;
    Result := (ShFileOperation(fos) = 0);
  except
    Result := False;
  end;
end;


function MoveFileDir(const fromDir, toDir: string): Boolean;
var
  fos: TSHFileOpStruct; 
begin 
  try
    ZeroMemory(@fos, SizeOf(fos));
    with fos do 
    begin 
      wFunc  := FO_MOVE; 
      pFrom  := PChar(fromDir + #0);
      pTo    := PChar(toDir + #0);
      fFlags := FOF_NOCONFIRMATION or FOF_NOERRORUI or FOF_SILENT or FOF_NOCONFIRMMKDIR;
    end;
    Result := (ShFileOperation(fos) = 0); 
  except
    Result := False;
  end;
end;

function CopyFileWithArbitraryName(const sourcePath, destinationDir, destinationFileName: string): Boolean;
var
  SourceFile, DestinationFile: string;
begin
  Result := False;

  DestinationFile := TPath.Combine(destinationDir, destinationFileName);

  try
    // Check if the destination directory exists, create it if not
    if not DirectoryExists(destinationDir) then
      ForceDirectories(destinationDir);

    // Use the TFile.Copy function to copy the file
    TFile.Copy(sourcePath, destinationFile);

    // Set the result to True if the copy operation was successful
    Result := True;
  Except
    on E: Exception do begin
      ErrorLog('utilFile.CopyFileWithArbitraryName: Error: ' + E.Message);
    end;
  End;
end;

function OverlapDirectory(const fromDir, toDir: string): Boolean;
begin
  Result := MoveFileDir(fromDir + PathDelim + '*.*', toDir);
  if Result then
    RemoveDir(fromDir);
end;

function DelTree(DirName : string): Boolean;
var
  fos : TSHFileOpStruct;
begin
  { TODO ! : not tested .. ensure deleted directories/files are not accessible by Recycle Bin }
  try
    ZeroMemory(@fos, Sizeof(fos));
    with fos do begin
      wFunc := FO_DELETE;
      pFrom := PChar(DirName + #0);
      fFlags := FOF_NOCONFIRMATION or FOF_NOERRORUI or FOF_SILENT;
    end;
    Result := (SHFileOperation(fos) = 0) ;
  except
    Result := False;
  end;
end;

procedure CleanupFiles(Dir: String; FilesBefore: TDateTime);
var
  sr: TSearchRec;
begin
  if FindFirst(Dir + PathDelim + '*', faDirectory, sr) = 0 then
  begin
    try
      repeat
        if (FileDateToDateTime(sr.Time) < FilesBefore) then
        begin
          if (faDirectory and sr.Attr) <> 0 then
            DelTree(Dir + PathDelim + sr.Name)
          else
            DeleteFile(Dir + PathDelim + sr.Name);
        end;
      until FindNext(sr) <> 0;
    finally
      FindClose(sr);
    end;
  end;
end;

function IsEmptyFolder(const Folder: String): Boolean;
var
  SearchRec: TSearchRec;
begin
  if FindFirst(Folder + PathDelim + '*', -1, SearchRec) = 0 then
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          Result := false;
          exit;
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;

  Result := true;
end;

function DeleteFileNotExistsIsTrue(const FileName: String): Boolean;
begin
  Result := DeleteFile(FileName) or (GetLastError = ERROR_FILE_NOT_FOUND);
end;

function DeleteFileAndEmptyFolder(const FileName, StopFolder: String): Boolean;
var Folder: String;
begin
  Result := DeleteFileNotExistsIsTrue(FileName);
  Folder := ExcludeTrailingPathDelimiter(ExtractFilePath(FileName));

  while (Folder <> '') and (Folder <> StopFolder) do
  begin
    if DeleteFile(Folder) then
      Folder := ExcludeTrailingPathDelimiter(ExtractFilePath(FileName))
    else
      Folder := '';
  end;
end;

function BrowseCallbackProc(hwnd: HWND; uMsg: UINT; lParam: LPARAM; lpData: LPARAM): Integer; stdcall;
begin
  if (uMsg = BFFM_INITIALIZED) then
    SendMessage(hwnd, BFFM_SETSELECTION, 1, lpData);
  BrowseCallbackProc := 0;
end;

// Added by Rym: Open built-in Windows select folder dialog
function GetFolderDialog(Handle: Integer; Caption: string; var strFolder: string): Boolean;
const
  BIF_STATUSTEXT           = $0004;
  BIF_NEWDIALOGSTYLE       = $0040;
  BIF_RETURNONLYFSDIRS     = $0080;
  BIF_SHAREABLE            = $0100;
  BIF_USENEWUI             = BIF_EDITBOX or BIF_NEWDIALOGSTYLE;

var
  BrowseInfo: TBrowseInfo;
  ItemIDList: PItemIDList;
  JtemIDList: PItemIDList;
  Path: PWideChar;
begin
  Result := False;
  Path := StrAlloc(MAX_PATH);
  SHGetSpecialFolderLocation(Handle, CSIDL_DRIVES, JtemIDList);
  with BrowseInfo do
  begin
    hwndOwner := GetActiveWindow;
    pidlRoot := JtemIDList;
    SHGetSpecialFolderLocation(hwndOwner, CSIDL_DRIVES, JtemIDList);

    { return display name of item selected }
    pszDisplayName := StrAlloc(MAX_PATH);

    { set the title of dialog }
    lpszTitle := PChar(Caption);//'Select the folder';
    { flags that control the return stuff }
    lpfn := @BrowseCallbackProc;
    { extra info that's passed back in callbacks }
    lParam := LongInt(PChar(strFolder));

    ulFlags := BIF_RETURNONLYFSDIRS or BIF_NEWDIALOGSTYLE or BIF_VALIDATE;
  end;

  ItemIDList := SHBrowseForFolder(BrowseInfo);

  if (ItemIDList <> nil) then
    if SHGetPathFromIDList(ItemIDList, Path) then
    begin
      strFolder := Path;
      Result := True
    end;
end;

function getLastErrorStringEx : String;
var
  LastError: Cardinal;
begin
  Result := getLastErrorString(GetLastError());
end;

function getLastErrorString(LastError: Cardinal) : String;
var
 ErrorString: Array [0..1024] of Char;
begin
  Result := '[No system error listed]';

  If LastError <> 0 Then Begin
    FormatMessage(
        FORMAT_MESSAGE_FROM_SYSTEM,
        Pointer(FORMAT_MESSAGE_FROM_HMODULE),
        LastError,
        0,
        @ErrorString,
        1024,
        Nil);
  End;

  Result := AnsiString( ErrorString );
end;


function RunFileShellExecuteSimple(Handle: HWND; FileName: String): boolean;
var
  StrBuf: String;
  ExecResult: Cardinal;
begin
  ExecResult := ShellExecute( Handle, PChar('open'), PChar( FileName ), Nil, Nil, SW_SHOWNORMAL );
  if ExecResult < 32 then
  begin
     StrBuf := 'Error executing file:'+  FileName +'. Error:"'+ getLastErrorStringEx();
     if Not( FileExists( FileName)) then
       StrBuf := StrBuf +#13#10'Source file does not exist!';
     ErrorLog(StrBuf);
     ShowMessage( StrBuf );
  end;
end;

function ReadFileContentAsJsonValue(fileName: String): TJSONValue;
var
  fileTextContent: string;
  fileJsonContent: TJsonValue;
begin
  try
    if Not( FileExists( FileName)) then begin
      ErrorLog('utilFile.ReadFileContentAsJsonValue: Error: ' + FileName + 'does not exist!');
      Result := nil;
      exit;
    end;

    fileTextContent := TFile.ReadAllText(fileName);
    Result := TJsonObject.ParseJsonValue(fileTextContent);
  Except
    on E: Exception do begin
      ErrorLog('utilFile.ReadFileContentAsJsonValue: Error: ' + E.Message);
      Result := nil;
    end;
  End;
end;

end.

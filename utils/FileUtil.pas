unit FileUtil;

interface

uses Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, System.Types, System.StrUtils;

type
TResultType = (rtErrorOutput, rtStandardOutput);

TFileExtensions = record
  const
    JPG = 'jpg';
    BMP = 'bmp';
end;

function GetTemporaryFolderPath: string;
function GetFileVersion(Filename: string): string;
function GetDosOutput(Command, Params: String; resultType: TResultType = rtErrorOutput): String;
procedure SaveBytesToFile(const Data: TBytes; const FileName: string);
function ReadFileWithStreamReader(const FilePath: string): string;
function GetLastElementFromStringByDelimiter(const AText, ADelimiter: string): string;
function GetFileNameByIndexInFolder(const folderPath: string; index: Integer): String;
function GetFolderPathByIndex(const parentFolder: string; folderIndex: Integer): string;
function GetNumberOfFilesInAFolder(const folderPath: string): Integer;
function GetNumberOfSubfolders(const FolderPath: string): Integer;
function GetFirstFileExtension(const folderPath: string): string;
function validateFileName( BaseFolder, BaseFileName: String ): String;
function getSaveFileNameAutoExtension( BaseFolder, BaseFileName: String ): String;

implementation

uses BasicLogger;

function GetTemporaryFolderPath: string;
var
 tmpChar: Array [0..512] of Char;
begin
  Result := string.Empty;
  try
    // Locate temporary directory
    GetTempPath( 512, tmpChar );
    Result := AnsiString( tmpChar );
  except
  end;
end;

function GetFileVersion(Filename: string): string;
 var
    N, Len: DWORD;
    Buf: PChar;
    Value: PChar;
begin
  Result := '';
  N := GetFileVersionInfoSize(PChar(Filename), N);
  if N > 0 then
  begin
     Buf := AllocMem(N);
     GetFileVersionInfo(PChar(Filename), 0, N, Buf);
     if VerQueryValue(Buf,
                      PChar('StringFileInfo\040904E4\FileVersion'),
                      Pointer(Value), Len) then
        Result := Value;
     FreeMem(Buf, N);
  end;
end;

function AddQuotesIfNeeded(const S: String): String;
begin
  if (S = '') or (Pos(' ', S) <> 0) or (Pos('"', S) <> 0) then
    Result := AnsiQuotedStr(S, '"')
  else
    Result := S;
end;

function GetDosOutput(Command, Params: String; resultType: TResultType = rtErrorOutput): String;
var
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  PI: TProcessInformation;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  StdErrPipeRead, StdErrPipeWrite: THandle;
  WasOK: Boolean;
  Buffer: array[0..10240] of AnsiChar;
  BytesRead: Cardinal;
  Handle: Boolean;
  sCommand, WorkDir: String;
  FStandardOutput, FStandardError: String;


 StrBuf: string;
 LastError: Cardinal;
 ErrorString: Array [0..1024] of Char;
begin
  Result := '';
  FStandardOutput := '';
  FStandardError := '';

  with SA do begin
    nLength := SizeOf(SA);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;
  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);
  CreatePipe(StdErrPipeRead, StdErrPipeWrite, @SA, 0);
  try
    with SI do
    begin
      FillChar(SI, SizeOf(SI), 0);
      cb := SizeOf(SI);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      wShowWindow := SW_HIDE;
      hStdInput := GetStdHandle(STD_INPUT_HANDLE); // don't redirect stdin
      hStdOutput := StdOutPipeWrite;
      hStdError := StdErrPipeWrite;
    end;
    WorkDir := ExtractFileDir( Command );
    sCommand := AddQuotesIfNeeded( Command ) +' '+ Params;
    UniqueString(sCommand);
    Handle := CreateProcess( nil, PWideChar(sCommand),
                            nil, nil, True, 0, nil,
                            PChar(WorkDir), SI, PI);
    CloseHandle(StdOutPipeWrite);
    CloseHandle(StdErrPipeWrite);
    if Handle then begin
      try
        repeat
          // Read StdOut
          WasOK := ReadFile(StdOutPipeRead, Buffer, 102400, BytesRead, nil);
          if BytesRead > 0 then
          begin
            Buffer[BytesRead] := #0;
            FStandardOutput := FStandardOutput + AnsiString( Buffer );
          end;
        until not WasOK or (BytesRead = 0);

        repeat
          // Read StdErr
          WasOK := ReadFile(StdErrPipeRead, Buffer, 10240, BytesRead, nil);
          if BytesRead > 0 then
          begin
            Buffer[BytesRead] := #0;
            FStandardError := FStandardError + AnsiString( Buffer );
          end;
        until not WasOK or (BytesRead = 0);
        WaitForSingleObject(PI.hProcess, INFINITE);
      finally
//        CloseHandle(PI.hThread);
//        CloseHandle(PI.hProcess);
      end;
    end else begin
       LastError := GetLastError();
       If LastError <> 0 Then begin
         FormatMessage( FORMAT_MESSAGE_FROM_SYSTEM,Pointer(FORMAT_MESSAGE_FROM_HMODULE),LastError,0,@ErrorString,1024,Nil);
         StrBuf := 'i2k Retina SYSTEM ERROR: '+ AnsiString( ErrorString );
         Result := StrBuf;
         exit;
       end; // If a Windows Error is defined
    end;

    if resultType = rtStandardOutput then
      Result := FStandardOutput;
    if resultType = rtErrorOutput then
      Result := FStandardError;

  finally
    CloseHandle(StdOutPipeRead);
    CloseHandle(StdErrPipeRead);
  end;
end;

procedure SaveBytesToFile(const Data: TBytes; const FileName: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    if Data <> nil then
      Stream.WriteBuffer(Data[0], Length(Data));
  finally
    Stream.Free;
  end;
end;

function ReadFileWithStreamReader(const FilePath: string): string;
var
  FileStream: TFileStream;
  StreamReader: TStreamReader;
begin
  try
    FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
    StreamReader := TStreamReader.Create(FileStream, TEncoding.UTF8);
    try
      Result := StreamReader.ReadToEnd;
    Except
      on E: Exception do
        ErrorLog('ReadFileWithStreamReader: Error: ' + E.Message);
    End;
  finally
    StreamReader.Free;
    FileStream.Free;
  end;
end;

function GetLastElementFromStringByDelimiter(const AText, ADelimiter: string): string;
var
  SplitResult: TStringDynArray;
begin
  try
    SplitResult := SplitString(AText, ADelimiter);
    if Length(SplitResult) > 0 then
      Result := SplitResult[Length(SplitResult) - 1]
    else
      Result := '';
  Except
    on E: Exception do
      ErrorLog('GetLastElementFromStringByDelimiter: Error: ' + E.Message);
  End;
end;

function GetFileNameByIndexInFolder(const folderPath: string; index: Integer): String;
var
  searchResult: TSearchRec;
  currentIndex: Integer;
begin
  try
    Result := '';

    // Check if the folder exists
    if not DirectoryExists(folderPath) then
    begin
      ErrorLog('GetFileNameByIndexInFolder: Folder does not exist. Folder path: ' + folderPath + ' Index: ' + IntToStr(index));
      Exit;
    end;

    currentIndex := 0;

    // Find the files in the folder
    if FindFirst(folderPath + '\*.*', faAnyFile, searchResult) = 0 then
    begin
      try
        repeat
          if (searchResult.Attr and faDirectory) = 0 then
          begin
            if currentIndex = index then
            begin
              Result := searchResult.Name;
              Break;
            end;
            Inc(currentIndex);
          end;
        until (currentIndex > index) or (FindNext(searchResult) <> 0);
      finally
        FindClose(searchResult);
      end;
    end
    else
    begin
      ErrorLog('GetFileNameByIndexInFolder: No files found in the folder. Folder path: ' + folderPath + ' Index: ' + IntToStr(index));
    end;
  Except
    on E: Exception do
      ErrorLog('GetFileNameByIndexInFolder: Folder path: ' + folderPath + ' Index: ' + IntToStr(index) + ' Error: ' + E.Message);
  End;
end;

function GetFolderPathByIndex(const parentFolder: string; folderIndex: Integer): string;
var
  searchRec: TSearchRec;
  foundFolders: Integer;
begin
  try
    Result := '';

    if FindFirst(IncludeTrailingPathDelimiter(parentFolder) + '*', faDirectory, searchRec) = 0 then
    begin
      try
        foundFolders := 0;
        repeat
          if (searchRec.Attr and faDirectory) <> 0 then
          begin
            if (searchRec.Name <> '.') and (searchRec.Name <> '..') then
            begin
              if foundFolders = folderIndex then
              begin
                Result := parentFolder + '\' + searchRec.Name;
                Break;
              end;
              Inc(foundFolders);
            end;
          end;
        until FindNext(searchRec) <> 0;
      finally
        FindClose(searchRec);
      end;
    end;
  Except
    on E: Exception do
      ErrorLog('GetFolderPathByIndex: Parent folder path: ' + parentFolder + ' Index: ' + IntToStr(folderIndex) + ' Error: ' + E.Message);
  End;
end;


function GetNumberOfFilesInAFolder(const folderPath: string): Integer;
var
  searchRec: TSearchRec;
begin
  try
    Result := 0;
    // Initialize the search and check for errors
    if FindFirst(IncludeTrailingPathDelimiter(folderPath) + '*.*', faAnyFile, searchRec) = 0 then
    begin
      try
        repeat
          // Check if the found item is a file (not a directory)
          if (searchRec.Attr and faDirectory) = 0 then
            Inc(Result); // It's a file, so increment the count
        until FindNext(searchRec) <> 0; // Continue until no more items
      finally
        FindClose(searchRec); // Close the search handle
      end;
    end;
  Except
    on E: Exception do
      ErrorLog('GetNumberOfFilesInAFolder: Folder path: ' + folderPath + ' Error: ' + E.Message);
  End;
end;


function GetNumberOfSubfolders(const FolderPath: string): Integer;
var
  SearchRec: TSearchRec;
  ResultCode: Integer;
  SubfolderCount: Integer;
begin
  try
    SubfolderCount := 0;

    ResultCode := FindFirst(IncludeTrailingPathDelimiter(FolderPath) + '*.*', faDirectory, SearchRec);
    try
      while ResultCode = 0 do
      begin
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') and (SearchRec.Attr and faDirectory = faDirectory) then
          Inc(SubfolderCount);

        ResultCode := FindNext(SearchRec);
      end;
    finally
      FindClose(SearchRec);
    end;

    Result := SubfolderCount;
  Except
    on E: Exception do
      ErrorLog('GetNumberOfSubfolders: Folder path: ' + FolderPath + ' Error: ' + E.Message);
  End;
end;

function GetFirstFileExtension(const folderPath: string): string;
var
  searchRec: TSearchRec;
begin
  try
    Result := '';

    if FindFirst(IncludeTrailingPathDelimiter(folderPath) + '*.*', faAnyFile, searchRec) = 0 then
    begin
      try
        repeat
          if (searchRec.Attr and faDirectory) = 0 then
          begin
            Result := ExtractFileExt(searchRec.Name);
            Break;
          end;
        until FindNext(searchRec) <> 0;
      finally
        FindClose(searchRec);
      end;
    end;
  Except
    on E: Exception do
      ErrorLog('GetFirstFileExtension: Folder path: ' + folderPath + ' Error: ' + E.Message);
  End;
end;

/// Validate and return a unique file name
function validateFileName( BaseFolder, BaseFileName: String ): String;
begin
  if Not FileExists( BaseFolder + '\' + BaseFileName ) then
  begin
    Result := BaseFileName;
    exit;
  end else begin
    Result := getSaveFileNameAutoExtension( BaseFolder, BaseFileName );
  end;
end;

function getSaveFileNameAutoExtension( BaseFolder, BaseFileName: String ): String;
var
 k: Integer;
 FileName, FileExtension, BaseFileNameWithoutExtension: String;
 thisFileExists: Boolean;
begin
  FileExtension := ExtractFileExt(BaseFileName);
  BaseFileNameWithoutExtension := Copy( BaseFileName, 1, Length( BaseFileName )
                                       - Length( FileExtension ));

  if (Length(FileExtension)=0) then
    FileExtension := '.JPG';
  k := 1;
  Repeat
    thisFileExists := False;
    FileName := BaseFileNameWithoutExtension + InttoStr( k );
    k := k + 1;
    thisFileExists := FileExists( BaseFolder +'\'+ FileName +'.JPG')
                   or FileExists( BaseFolder +'\'+ FileName +'.PNG')
                   or FileExists( BaseFolder +'\'+ FileName +'.BMP')
  Until Not thisFileExists;
  Result := FileName + FileExtension;
end;

end.

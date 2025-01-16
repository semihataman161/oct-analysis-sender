unit HtmlToPdfConverter;

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, System.Net.HttpClient;

procedure SaveRawHtmlReportToTempFolder(jwtToken: String; baseURL: String; htmlReportTempPath: String; analysisGUID: String);
procedure SaveChangedHtmlReportToTempFolder(HtmlReportTempPath: String; HtmlTemplateDict: TDictionary<String, String>);
function CreateHtmlDoc(HtmlReportTempPath: String): String;
function ReplaceHtmlTemplateWithValues(HtmlDoc: String; HtmlTemplateDict: TDictionary<String, String>): String;
function SaveConvertedPdfReportToTempFolder(HtmlReportTempPath: String; PdfReportTempPath: String): Boolean;
function GetFontFamilyPath(FontFamilyFileName: String): String;

implementation

uses BasicLogger, RequestHelper, FileUtil;

procedure SaveRawHtmlReportToTempFolder(jwtToken: String; baseURL: String; htmlReportTempPath: String; analysisGUID: String);
var
  RequestHelper: TRequestHelper;
  response: IHTTPResponse;
  responseContent: String;
begin
  RequestHelper := nil;

  try
    try
      RequestHelper := TRequestHelper.Create(baseURL);
      response := RequestHelper.getRequest(jwtToken, AnalysisGUID);

      if response = nil then begin
        ErrorLog(EC_101 + ' Error : SaveRawHtmlReportToTempFolder: Url: ' + baseUrl + sLineBreak + RA_101);
        exit;
      end;

      responseContent := response.ContentAsString;

      if response.StatusCode <> 200 then begin
        ErrorLog(EC_101 + ' Error : SaveRawHtmlReportToTempFolder: Url: ' + baseUrl + ' Response: ' + responseContent + sLineBreak + RA_101);
        exit;
      end;

      if Length(responseContent) = 0 then begin
        ErrorLog('Error : SaveRawHtmlReportToTempFolder: Response is empty ' + ' Url: ' + baseUrl);
        exit;
      end;

      WriteToAbsoluteFile(htmlReportTempPath, responseContent);
    except
      on E: Exception do begin
        ErrorLog('SaveRawHtmlReportToTempFolder: Error while saving raw html report to ' + HtmlReportTempPath + ': ' + E.Message);
      end;
    end;
  finally
    RequestHelper.Free;
  end;
end;

procedure SaveChangedHtmlReportToTempFolder(HtmlReportTempPath: String; HtmlTemplateDict: TDictionary<String, String>);
var
  HtmlDoc: String;
  ChangedHtmlText: TStringList;
begin
  ChangedHtmlText := nil;

  try
    try
      HtmlDoc := createHtmlDoc(HtmlReportTempPath);
      HtmlDoc := replaceHtmlTemplateWithValues(HtmlDoc, HtmlTemplateDict);

      ChangedHtmlText := TStringList.Create;
      ChangedHtmlText.Add(HtmlDoc);
      ChangedHtmlText.SaveToFile(htmlReportTempPath, TEncoding.UTF8);

      //  CopyFile(PChar(htmlFile),PChar(htmlFile),false);
    except
      on E: Exception do begin
        ErrorLog('SaveChangedHtmlReportToTempFolder: Error while saving changed html report to ' + HtmlReportTempPath + ': ' + E.Message);
      end;
    end;
  finally
    ChangedHtmlText.Free;
  end;
end;

function CreateHtmlDoc(HtmlReportTempPath: String): String;
var
  Stream : TStringStream;
begin
  Stream := nil;

  try
    try
      Stream := TStringStream.Create('', TEncoding.UTF8);
      Stream.LoadFromFile(HtmlReportTempPath);
      Result := Stream.DataString;
    except
      on E: Exception do begin
        ErrorLog('CreateHtmlDoc: Error while reading html file! ' + HtmlReportTempPath + ': ' + E.Message);
      end;
    end;
  finally
    Stream.Free;
  end;
end;

function ReplaceHtmlTemplateWithValues(HtmlDoc: String; HtmlTemplateDict: TDictionary<String, String>): String;
var
  Key, Value: String;
begin
  try
    try
      for Key in HtmlTemplateDict.Keys do
        begin
        Value := HtmlTemplateDict[Key];
        HtmlDoc := HtmlDoc.Replace(Key, Value);
      end;

      Result := HtmlDoc;
    except
      on E: Exception do begin
        ErrorLog('ReplaceHtmlTemplateWithValues: Error while replacing html template with patient related values! ' + E.Message);
      end;
    end;
  finally
    HtmlTemplateDict.Free;
  end;
end;

function SaveConvertedPdfReportToTempFolder(HtmlReportTempPath: String; PdfReportTempPath: String): Boolean;
const
  DONE = 'Done';
  ERROR = 'Error';
  DISABLE_SMART_SHRINKING = '--disable-smart-shrinking ';
  ENABLE_LOCAL_FILE_ACCESS = '--enable-local-file-access ';
var
  wkhtmltopdfExePath, wkhtmltopdfParams, outputMsg: string;
  isFileConvertedSuccessfully: boolean;
begin
  Result := False;

  try
     wkhtmltopdfExePath := GetPathTo('wkhtmltopdf.exe');
     wkhtmltopdfParams := DISABLE_SMART_SHRINKING + ENABLE_LOCAL_FILE_ACCESS + HtmlReportTempPath + ' ' + PdfReportTempPath;
     { 20230601; Semih: I call GetDosOutput with rtErrorOutput argument because rtStandardOutput always returns empty string and
      rtErrorOutput is returned full even if the conversion is successful.
     }
     outputMsg := GetDosOutput(wkhtmltopdfExePath, wkhtmltopdfParams, rtErrorOutput);

     isFileConvertedSuccessfully := FileExists(PdfReportTempPath) and outputMsg.Contains(DONE) and not outputMsg.Contains(ERROR);
     if isFileConvertedSuccessfully then begin
       // ErrorLog('SaveConvertedPdfReportToTempFolder: Converted html to pdf successfully: ' + outputMsg);
     end
     else begin
       ErrorLog('SaveConvertedPdfReportToTempFolder: Error occured while converting html to pdf: ' + outputMsg);
     end;

     Result := isFileConvertedSuccessfully;
  except
    on E: Exception do begin
      ErrorLog('SaveConvertedPdfReportToTempFolder: Error while converting html report in ' + HtmlReportTempPath +
               ' as pdf to '  + PdfReportTempPath +  ': ' + E.Message + ': ' + outputMsg);
    end;
  end;
end;

function GetFontFamilyPath(FontFamilyFileName: String): String;
var
  originalFontFamilyFilePath: String;
  fontFamilyPath: String;
begin
  try
    Result := '';

    originalFontFamilyFilePath := GetPathTo('\template\' + FontFamilyFileName);
    if not FileExists(originalFontFamilyFilePath) then begin
      abort;
    end;

    fontFamilyPath := 'file:///' + originalFontFamilyFilePath;
    Result := StringReplace(fontFamilyPath, '\', '//', [rfReplaceAll]);
  except
    on E: Exception do begin
      ErrorLog('GetFontFamilyPath: Error while getting font family path ' + E.Message);
    end;
  end;
end;

end.

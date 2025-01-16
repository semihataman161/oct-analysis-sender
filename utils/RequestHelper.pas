unit RequestHelper;

interface

uses System.Net.HttpClientComponent, System.Net.HttpClient, SysUtils, System.StrUtils,
System.JSON, REST.Json, REST.HttpClient, System.Classes, System.Net.MIME;

type

  TRequestHelper = class(TObject)
  private
    FBaseURL, FRequestFileName, FResponseFileName: String;
    function getEndpointURL(pathVariable: String): String;
    procedure setLogFileNames(endpointURL: String);
  public
    property baseURL: String read FBaseURL write FBaseURL;
    function getRequest(jwtToken: String = ''; pathVariable: String = ''): IHTTPResponse;
    function postRequest(requestString: String; jwtToken: String = ''; pathVariable: String = ''): IHTTPResponse; overload;
    function postRequest(multipartFormData: TMultipartFormData; jwtToken: String = ''; pathVariable: String = ''): IHTTPResponse; overload;
    constructor Create(baseURL: String);
  end;

implementation

uses BasicLogger, FileUtil;

const
  REQUEST = 'Request';
  RESPONSE = 'Response';
  CONNECTION_TIMEOUT_VALUE  = 600000;
  SEND_TIMEOUT_VALUE  = 600000;
  RESPONSE_TIMEOUT_VALUE = 600000;

{ TRequestHelper }
constructor TRequestHelper.Create(baseURL: String);
begin
  FBaseURL := baseURL;
end;

function TRequestHelper.getEndpointURL(pathVariable: String): String;
begin
  try
    if pathVariable.IsEmpty then begin
      Result := FBaseURL;
    end
    else begin
      Result := FBaseURL + '/' + pathVariable;
    end;
  Except
    on E: Exception do
      begin
        ErrorLog('TRequestHelper.getEndpointUrl error: ' + E.Message);
      end
  end;
end;

procedure TRequestHelper.setLogFileNames(endpointURL: string);
const
  DELIMITER = '/';
var
  endpointName: string;
begin
  try
    endpointName := getLastElementFromStringByDelimiter(FBaseURL, DELIMITER);
    FRequestFileName := 'log/' + endpointName + REQUEST + '.txt';
    FResponseFileName := 'log/' + endpointName + RESPONSE + '.txt';
  Except
    on E: Exception do
      begin
        ErrorLog('TRequestHelper.setErrorLogFileNames error: ' + E.Message);
      end
  end;
end;

function TRequestHelper.getRequest(jwtToken: String; pathVariable: String): IHTTPResponse;
var
  HttpClient: TNetHTTPClient;
  response: IHTTPResponse;
  endpointURL, responseContent: String;
  statusCode: Integer;
begin
  try
    Result := nil;

    endpointURL := getEndpointURL(pathVariable);
    setLogFileNames(endpointURL);

    WriteToRelativeFile(FRequestFileName, endpointURL);
    HttpClient := TNetHTTPClient.Create(nil);

    try
      HttpClient.ConnectionTimeout := CONNECTION_TIMEOUT_VALUE;
      HttpClient.SendTimeout := SEND_TIMEOUT_VALUE;
      HttpClient.ResponseTimeout := RESPONSE_TIMEOUT_VALUE;

      if not jwtToken.IsEmpty then begin
        HttpClient.CustomHeaders['Authorization'] := jwtToken;
      end;

      HttpClient.CustomHeaders['Content-Type'] :=  'application/json';
      HttpClient.CustomHeaders['Accept'] :=  'application/json, text/plain; q=0.9, text/html;q=0.8, */*';

      response := HttpClient.Get(endpointURL);
      statusCode := response.StatusCode;
      responseContent := response.ContentAsString;
      WriteToRelativeFile(FResponseFileName, 'Status Code: ' + statusCode.ToString + ': -> Response: ' + responseContent);

      Result := response;
    finally
      FreeAndNil(HttpClient);
    end;
     
  Except
    on E: Exception do
    begin
      ErrorLog('TRequestHelper: GetRequest error message: ' + E.Message);
      ErrorLog('TRequestHelper: GetRequest endpoint url: ' + endpointURL);
    end
  end;
end;

function TRequestHelper.postRequest(requestString: String; jwtToken: String; pathVariable: String): IHTTPResponse;
var
  HttpClient: TNetHTTPClient;
  response: IHTTPResponse;
  endpointURL, responseContent: String;
  statusCode: Integer;
  RequestStream: TStringStream;
begin
  try
    Result := nil;

    endpointURL := getEndpointURL(pathVariable);
    setLogFileNames(endpointURL);

    HttpClient := TNetHTTPClient.Create(nil);
    HttpClient.ConnectionTimeout := CONNECTION_TIMEOUT_VALUE;
    HttpClient.SendTimeout := SEND_TIMEOUT_VALUE;
    HttpClient.ResponseTimeout := RESPONSE_TIMEOUT_VALUE;

    if not jwtToken.IsEmpty then begin
      HttpClient.CustomHeaders['Authorization'] := jwtToken;
    end;

    HttpClient.CustomHeaders['Content-Type'] :=  'application/json';
    HttpClient.CustomHeaders['Accept'] :=  'application/json, text/plain; q=0.9, text/html;q=0.8, */*';

    WriteToRelativeFile(FRequestFileName, endpointURL + sLineBreak + requestString);
    RequestStream := TStringStream.Create(requestString, TEncoding.UTF8);

    try
      response := HttpClient.Post(endpointURL, RequestStream);
      statusCode := response.StatusCode;
      responseContent := response.ContentAsString;
      WriteToRelativeFile(FResponseFileName, 'Status Code: ' + statusCode.ToString + ': -> Response: ' + responseContent);

      Result := response;
    finally
      FreeAndNil(HttpClient);
      FreeAndNil(RequestStream);
    end;
  Except
    on E: Exception do
      begin
        ErrorLog('TRequestHelper: PostRequest error message: ' + E.Message);
        ErrorLog('TRequestHelper: PostRequest endpoint url: ' + endpointURL);
      end
  end;

end;

function TRequestHelper.postRequest(multipartFormData: TMultipartFormData; jwtToken: String; pathVariable: String): IHTTPResponse;
var
  HttpClient: TNetHTTPClient;
  response: IHTTPResponse;
  endpointURL, responseContent: String;
  statusCode: Integer;
  FileStream: TFileStream;
begin
  try
    Result := nil;

    endpointURL := getEndpointURL(pathVariable);
    setLogFileNames(endpointURL);

    HttpClient := TNetHTTPClient.Create(nil);
    HttpClient.ConnectionTimeout := CONNECTION_TIMEOUT_VALUE;
    HttpClient.SendTimeout := SEND_TIMEOUT_VALUE;
    HttpClient.ResponseTimeout := RESPONSE_TIMEOUT_VALUE;

    if not jwtToken.IsEmpty then begin
      HttpClient.CustomHeaders['Authorization'] := jwtToken;
    end;

    HttpClient.CustomHeaders['Content-Type'] :=  'application/json';
    HttpClient.CustomHeaders['Accept'] :=  'application/json, text/plain; q=0.9, text/html;q=0.8, */*';

    WriteToRelativeFile(FRequestFileName, endpointURL + sLineBreak);
    FileStream := TFileStream.Create(FRequestFileName, fmOpenWrite or fmShareDenyWrite);

    try
      FileStream.Seek(0, soFromEnd);
      multipartFormData.Stream.SaveToStream(FileStream);
      response := HttpClient.Post(endpointURL, multipartFormData);
      statusCode := response.StatusCode;
      responseContent := response.ContentAsString;
      WriteToRelativeFile(FResponseFileName, 'Status Code: ' + statusCode.ToString + ': -> Response: ' + responseContent);

      Result := response;
    finally
      FreeAndNil(HttpClient);
      FreeAndNil(FileStream);
      FreeAndNil(multipartFormData);
    end;
  Except
    on E: Exception do
    begin
      ErrorLog('TRequestHelper: PostRequest error message: ' + E.Message);
      ErrorLog('TRequestHelper: PostRequest endpoint url: ' + endpointURL);
    end
  end;
end;

end.

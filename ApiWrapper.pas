unit ApiWrapper;

interface
uses DTO, Vcl.Imaging.jpeg, System.JSON, System.Net.HttpClient, Rest.Json, System.SysUtils, System.Win.Registry,
     OCTSettingsManager, System.Net.Mime, System.Classes, Vcl.Dialogs, Vcl.Forms;

type
  TApiWrapper = class(TForm)
  private
    FOCTSettingsManager: TOCTSettingsManager;
  public
    procedure sendClientLog(level: Integer; pMessage: String);
    function createToken : String;
    function createAnalysis(dto : TCreateAnalysisRequestDTO): TCreateAnalysisResponseDTO;
    function startAnalysis(jwtToken, guid: String): Boolean;
    function getAnalysis(jwtToken, guid: String): TAnalysisResponseObj;
    constructor Create(OCTSettingsManager: TOCTSettingsManager);
  end;

implementation
uses RequestHelper, BasicLogger, RegistrationModel;

{ TApiWrapper }
constructor TApiWrapper.Create(OCTSettingsManager: TOCTSettingsManager);
begin
  FOCTSettingsManager := OCTSettingsManager;
end;

procedure TApiWrapper.sendClientLog(level: Integer; pMessage: String);
var
  JwtToken, responseContent, baseUrl: String;
  jsonObj : TJSONObject;
  sendClientLogRequestDTO: TSendClientLogRequestDTO;
  RequestHelper: TRequestHelper;
  response: IHTTPResponse;
begin
  jsonObj := nil;
  RequestHelper := nil;
  sendClientLogRequestDTO := TSendClientLogRequestDTO.Create;

  try
    ErrorLog('TApiWrapper.sendClientLog: Level' + level.ToString + ' Message: ' + pMessage);

    try
      sendClientLogRequestDTO.level := level;
      sendClientLogRequestDTO.message := pMessage;
      jsonObj := TJSON.ObjectToJsonObject(sendClientLogRequestDTO);

      JwtToken := createToken;

      if JwtToken.IsEmpty then begin
        ErrorLog('INFO: TApiWrapper.sendClientLog: JwtToken is empty ');
        exit;
      end;

      baseUrl := FOCTSettingsManager.ApiUrl + '/api/log/sendClientLog';
      RequestHelper := TRequestHelper.Create(baseUrl);
      response := RequestHelper.postRequest(jsonObj.ToString, JwtToken);

      if response = nil then begin
        ErrorLog(EC_101 + ' Error : TApiWrapper.sendClientLog: Url: ' + baseUrl + ' Request: ' + jsonObj.ToString + sLineBreak + RA_101);
        exit;
      end;

      responseContent := response.ContentAsString;

      if response.StatusCode <> 200 then begin
        ErrorLog('Error : TApiWrapper.sendClientLog: Url: ' + baseUrl + ' Request: ' + jsonObj.ToString + ' Response: ' + responseContent);
        exit;
      end;
      Except on E:Exception do begin
        ErrorLog('Error : Error occured while sending log to api : ' + E.Message);
        exit;
      end;
    end;
  finally
    jsonObj.Free;
    sendClientLogRequestDTO.Free;
    RequestHelper.Free;
  end;
end;

function TApiWrapper.createToken : String;
var
  jwtToken,regString,activationCode, responseContent,
  jwtJsonText, baseUrl: String;
  RequestHelper: TRequestHelper;
  jwtRequestJsonObj: TJSONObject;
  jwtJsonValue : TJSonValue;
  response: IHTTPResponse;
  registrationInfo: TRegistrationInfo;
begin
  RequestHelper := nil;
  jwtRequestJsonObj := nil;
  jwtJsonValue := nil;
  try
    try
      Result := '';
      registrationInfo := FOCTSettingsManager.ReadActivationInfo;
      regString := registrationInfo.RegKey;

      if regString.IsEmpty then begin
        ErrorLog('INFO: TApiWrapper.createToken: RegString(Product Key) is empty ');
        exit;
      end;

      activationCode := registrationInfo.ActivationCode;
      jwtRequestJsonObj := TJSONObject.Create;
      jwtRequestJsonObj.AddPair('username', regString);
      jwtRequestJsonObj.AddPair('password', activationCode);

      baseUrl := FOCTSettingsManager.ApiUrl + '/api/user/createToken';
      RequestHelper := TRequestHelper.Create(baseUrl);
      response := RequestHelper.postRequest(jwtRequestJsonObj.ToString);

      if response = nil then begin
        ErrorLog(EC_101 + ' Error : TApiWrapper.createToken: Url: ' + baseUrl + ' Request: ' + jwtRequestJsonObj.ToString + sLineBreak + RA_101);
        exit;
      end;

      responseContent := response.ContentAsString;

      if response.StatusCode <> 200 then begin
        ErrorLog('Error : TApiWrapper.createToken: Url: ' + baseUrl + ' Request: ' + jwtRequestJsonObj.ToString + ' Response: ' + responseContent);
        exit;
      end;

      jwtJsonValue := TJSonObject.ParseJSONValue(responseContent);
      jwtJsonValue.TryGetValue('data.jwtToken', jwtJsonText);
      jwtJsonText := StringReplace(jwtJsonText,'"','',[rfReplaceAll, rfIgnoreCase]);

      jwtToken := 'Bearer '+ jwtJsonText;
      Result := jwtToken;
    except
      on E : Exception do
      begin
        ErrorLog('TApiWrapper.createToken: Error reading registry and creating json object! ' + E.ToString);
        exit;
      end;
    end;
  finally
    RequestHelper.Free;
    jwtRequestJsonObj.Free;
    jwtJsonValue.Free;
  end;
end;

function TApiWrapper.createAnalysis(dto : TCreateAnalysisRequestDTO): TCreateAnalysisResponseDTO;
var
  CreateAnalysisResponse: TCreateAnalysisResponseDTO;
  jwtToken,responseContent,analysisGuid, baseUrl: String;
  responseJsonVal: TJSONValue;
  RequestHelper: TRequestHelper;
  requestJsonObject: TJsonObject;
  response: IHTTPResponse;
  presignedUrls: TArray<String>;
begin
  Result := nil;
  RequestHelper := nil;
  requestJsonObject := nil;
  responseJsonVal := nil;

  try
    try
      Result := Nil;

      baseUrl := FOCTSettingsManager.ApiUrl + '/api/octAnalysis/createAnalysis';
      RequestHelper := TRequestHelper.Create(baseUrl);
      requestJsonObject := TJSON.ObjectToJsonObject(dto);
      jwtToken := createToken;
      response := RequestHelper.postRequest(requestJsonObject.ToString, jwtToken);

      if response = nil then begin
        ErrorLog(EC_101 + ' Error : TApiWrapper.createAnalysis: Url: ' + baseUrl + ' Request: ' + requestJsonObject.ToString + sLineBreak + RA_101);
        exit;
      end;

      responseContent := response.ContentAsString;

      if response.StatusCode <> 200 then begin
        ErrorLog('Error : TApiWrapper.createAnalysis: Url: ' + baseUrl + ' Request: ' + requestJsonObject.ToString + ' Response: ' + responseContent);
        exit;
      end;

      responseJsonVal := TJSONObject.ParseJSONValue(responseContent);
      responseJsonVal.TryGetValue('data.analysisGuid', analysisGuid);
      responseJsonVal.TryGetValue('data.presignedUrls', presignedUrls);
      createAnalysisResponse := TCreateAnalysisResponseDTO.Create;
      createAnalysisResponse.guid := analysisGuid;
      createAnalysisResponse.JwtToken := jwtToken;
      createAnalysisResponse.fPresignedUrls := presignedUrls;
      result := createAnalysisResponse;
    except
      on E:Exception do begin
        ErrorLog(EC_101 + 'TApiWrapper.createAnalysis: ERROR processing response! ' + E.ToString + sLineBreak + 'Response content: ' + responseContent + RA_101);
        sendClientLog(ERROR, EC_101 + ' ' + RA_101);
      end;
    end;
  finally
    RequestHelper.Free;
    requestJsonObject.Free;
    responseJsonVal.Free;
  end;
end;

function TApiWrapper.startAnalysis(jwtToken, guid: String): Boolean;
var
  baseUrl, responseContent : String;
  RequestHelper: TRequestHelper;
  response: IHTTPResponse;
begin
  Result := false;
  RequestHelper := nil;

  try
    try
      baseUrl := FOCTSettingsManager.ApiUrl + '/api/octAnalysis/startAnalysis';
      RequestHelper := TRequestHelper.Create(baseUrl);
      response := RequestHelper.postRequest('', jwtToken, guid);

      if response = nil then begin
        ErrorLog(EC_101 + ' Error : TApiWrapper.startAnalysis: Url: ' + baseUrl + '/' + guid + sLineBreak + RA_101);
        exit;
      end;

      responseContent := response.ContentAsString;

      if response.StatusCode = 200 then begin
        result := true;
      end
      else begin
        ErrorLog('Error : TApiWrapper.startAnalysis: Url: ' + baseUrl + '/' + guid + ' Response: ' + responseContent);
      end;
    except
      on E:Exception do begin
        ErrorLog(EC_101 + ' TApiWrapper.startAnalysis: ERROR processing response! ' + E.ToString + sLineBreak + 'Response contents: ' + responseContent + 'BaseUrl : ' + baseUrl + RA_101);
      end;
    end;
  finally
    RequestHelper.Free;
  end;
end;

function TApiWrapper.GetAnalysis(jwtToken, guid:string): TAnalysisResponseObj;
var
  baseUrl, responseContent: string;
  diagnosisPrediction: TAnalysisResponseObj;
  RequestHelper: TRequestHelper;
  response: IHTTPResponse;
begin
  Result := Nil;
  RequestHelper := nil;
  try
    try
      baseUrl := FOCTSettingsManager.ApiUrl + '/api/octAnalysis/getAnalysis';
      RequestHelper := TRequestHelper.Create(baseUrl);
      response := RequestHelper.getRequest(jwtToken, guid);

      if response = nil then begin
        ErrorLog(EC_101 + ' Error : TApiWrapper.GetAnalysis: Url: ' + baseUrl + ' Request: ' + baseUrl + sLineBreak + RA_101);
        exit;
      end;

      responseContent := response.ContentAsString;

      if response.StatusCode <> 200 then begin
        ErrorLog(EC_101 + ' Error : TApiWrapper.GetAnalysis: Url: ' + baseUrl + ' Request: ' + baseUrl + ' Response: ' + responseContent + sLineBreak + RA_101);
        exit;
      end;

      if responseContent.IsEmpty then
      begin
        ErrorLog('TApiWrapper.GetAnalysis: Error: Server returned nothing...');
        exit;
      end;

      diagnosisPrediction := TJson.JsonToObject<TAnalysisResponseObj>(responseContent);
      responseContent := TJSON.ObjectToJsonString(diagnosisPrediction);
      result := diagnosisPrediction;

      if not diagnosisPrediction.success then begin
        ErrorLog('Error : GetResult endpoint failed! Api Message :  ' + diagnosisPrediction.message);
        sendClientLog(ERROR, EC_001 + ' ' + diagnosisPrediction.message + ' ' + RA_001);
      end;

    Except
      on E: Exception do
      begin
        ErrorLog(EC_102 + 'TApiWrapper.GetAnalysis Error: ' + E.Message + RA_102);
        sendClientLog(ERROR, EC_102 + ' Analysis error! ' + E.Message + ' ' + RA_102);
      end;
    End;
  finally
    RequestHelper.Free;
  end;
end;

end.

unit UploadManager;
{$include defines.inc}

interface

uses System.Win.Registry, Winapi.Windows, System.SysUtils, Vcl.Forms, REST.Json,
     System.Generics.Collections, System.Classes, System.JSON, OCTSettingsManager,
     ApiWrapper, UploadWorker, BasicLogger, DTO, System.SyncObjs,
     Data.DB, DateUtils;

type
  TUploadManager = class(TThread)
  private
    { Private declarations }
    FOCTSettingsManager: TOCTSettingsManager;
    FApiWrapper: TApiWrapper;
    FUploadWorkers: TList<TUploadWorker>;
    procedure setAnomalies(anomalies: TArray<String>; UploadWorkerData: TUploadWorkerData);
    function setHtmlTemplateDict(muayeneId: Integer): TDictionary<String, String>;
    function LoadPdfReport(UploadWorkerData: TUploadWorkerData): Boolean;
    procedure UploadWorkerSuccessFinishedHandler(Sender: TObject; UploadWorkerData: TUploadWorkerData);
    procedure UploadWorkerFailureFinishedHandler(Sender: TObject; UploadWorkerData: TUploadWorkerData);
    procedure GetAnalysis(UploadWorkerData: TUploadWorkerData);
    procedure ImportPdfReport(sourceFilePath: String; UploadWorkerData: TUploadWorkerData);
    procedure DestroyUploadWorkers;
  protected
    procedure Execute; override;
  public
    { Public declarations }
    procedure CleanFinishedWorkers;
    procedure DestroyUploadWorker(UploadWorker: TUploadWorker);
    constructor Create(OCTSettingsManager: TOCTSettingsManager; ApiWrapper: TApiWrapper);
    destructor Destroy; override;
  end;

implementation

uses UploadDataModule, FileUtil, HtmlToPdfConverter, utilFile, EcuImageType, QueueStatus;

var
  imageDir, imageDirDefault: String;

{ TfrmUploaderMain }

procedure TUploadManager.CleanFinishedWorkers;
begin
  for var item in FUploadWorkers do begin
    if item.Finished then begin
      FUploadWorkers.Remove(item);
      item.Free;
    end;
  end;
end;

constructor TUploadManager.Create(OCTSettingsManager: TOCTSettingsManager; ApiWrapper: TApiWrapper);
Var
 Reg: TRegistry;
begin
  ErrorLog('TUploadManager.Create: Launching...');
  inherited Create(True);
  FreeOnTerminate := False;

  FOCTSettingsManager := OCTSettingsManager;
  FApiWrapper := ApiWrapper;
  FUploadWorkers := TList<TUploadWorker>.Create;

  Try
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;
    imageDirDefault := GetPathTo('Images');
    mySqlHost := FOCTSettingsManager.C_MYSQL_HOST_DEFAULT;
    If Reg.OpenKeyReadOnly(FOCTSettingsManager.REG_IMAGING_KEY) Then
    begin
      If Reg.ValueExists(FOCTSettingsManager.REG_IMAGE_DIR_VAL ) Then
        imageDirDefault := Reg.ReadString(FOCTSettingsManager.REG_IMAGE_DIR_VAL);
      // 20100903; Rym: Add support for remote database
      If Reg.ValueExists(FOCTSettingsManager.REG_MYSQL_HOST) Then
        mySqlHost := Reg.ReadString(FOCTSettingsManager.REG_MYSQL_HOST);
    end;
    Reg.Free;
  Except
    on E : Exception do
    begin
      ErrorLog(EC_001 + 'Error reading Registry! '+ E.Message + RA_001);
      FApiWrapper.sendClientLog(ERROR, EC_001 + ' Error reading Registry! ' +  E.Message + ' ' + RA_001);
    end;
  End;

{$ifndef REMOTE_CLIENT}
  imageDir := imageDirDefault;
{$endif}
end;

destructor TUploadManager.Destroy;
begin
  try
    DestroyUploadWorkers;
  Except
    on E: Exception do
      ErrorLog('TUploadManager.Destroy: Error: ' + E.Message );
  End;
end;

procedure TUploadManager.DestroyUploadWorker(UploadWorker: TUploadWorker);
begin
  try
    UploadWorker.Terminate;
    UploadWorker.WaitFor;
    FUploadWorkers.Remove(UploadWorker);
  Except
    on E: Exception do
      ErrorLog('TUploadManager.DestroyUploadWorker: Error: ' + E.Message);
  End;
end;

procedure TUploadManager.DestroyUploadWorkers;
begin
  try
    for var I := 0 to FUploadWorkers.Count - 1 do begin
      FUploadWorkers[I].Terminate;
      FUploadWorkers[I].WaitFor;
      FUploadWorkers[I].Free;
    end;
    FUploadWorkers.Clear;
    FUploadWorkers.Free;
  Except
    on E: Exception do
      ErrorLog('TUploadManager.DestroyUploadWorkers: Error: ' + E.Message );
  End;
end;

procedure TUploadManager.GetAnalysis(UploadWorkerData: TUploadWorkerData);
const
  GET_ANALYSIS_SLEEP_TIME_MS = 30*1000;//30secs
  TIMEOUT_MINS = 15*60*1000;//15mins
var
  GetAnalysisResponse: TAnalysisResponseObj;
  imageInfosJsonArray: TJsonArray;
  startDateTime: TDateTime;
begin
  GetAnalysisResponse := nil;
  imageInfosJsonArray := nil;
  startDateTime := Now();

  try
    while true do begin

      if Now() >= IncMinute(startDateTime, TIMEOUT_MINS) then begin
        pUploadDataModule.CreateOrUpdateAnalysis(UploadWorkerData.analysisGuid, UploadWorkerData.muayeneID, UploadWorkerData.imageID, TIMEOUT_WHILE_GETTING_OCT_ANALYSIS);
        exit;
      end;

      GetAnalysisResponse := FApiWrapper.getAnalysis(UploadWorkerData.jwtToken, UploadWorkerData.analysisGuid);

      if GetAnalysisResponse = nil then begin
        ErrorLog('Service returned nothing for guid : Error: ' + UploadWorkerData.analysisGuid);
        pUploadDataModule.CreateOrUpdateAnalysis(UploadWorkerData.analysisGuid, UploadWorkerData.muayeneID, UploadWorkerData.imageID, ERROR_WHILE_GETTING_OCT_ANALYSIS);
        exit;
      end;

      try
        imageInfosJsonArray := TJsonArray.Create;

        if not GetAnalysisResponse.data.ready then begin
          Sleep(GET_ANALYSIS_SLEEP_TIME_MS);
          continue;
        end;

        setAnomalies(GetAnalysisResponse.data.foundAnomalies, UploadWorkerData);

        for var imageInfo in GetAnalysisResponse.data.imageInfos do begin
          imageInfosJsonArray.AddElement(TJson.ObjectToJsonObject(imageInfo));
        end;

        pUploadDataModule.UpdateImagePredictions(imageInfosJsonArray.ToString, UploadWorkerData.imageID);

        if not LoadPdfReport(UploadWorkerData) then
          exit;

        pUploadDataModule.SetQueueStatusCompleted(UploadWorkerData.analysisGuid, SUCCESSFULLY_COMPLETED_OCT_ANALYSIS);

        ErrorLog('Analysis completed with GUID: ' + UploadWorkerData.analysisGuid);

        exit;
      finally
        FreeAndNil(GetAnalysisResponse);
        FreeAndNil(imageInfosJsonArray);
      end;
    end;
  Except
    on E: Exception do
      ErrorLog('TUploadManager.GetAnalysis: Error: ' + E.Message );
  End;
end;

procedure TUploadManager.ImportPdfReport(sourceFilePath: String; UploadWorkerData: TUploadWorkerData);
var
  StrBuf, baseFile, destinationFilePath: String;
begin
  try
    baseFile := ExtractFileName(sourceFilePath);
    // Enforce a unique file name
    baseFile := validateFileName(imageDir, IntToStr(UploadWorkerData.hastaID) + '_' + IntToStr(UploadWorkerData.muayeneID) + '_' + BaseFile);

    // Copy image from original location to local IMAGES folder
    destinationFilePath := imageDir + PathDelim + BaseFile;

    if not CopyFile( PChar( sourceFilePath ), PChar( destinationFilePath ), False ) Then Begin
      StrBuf := 'Error while copying pdf report! From:' + sourceFilePath + '; TO:' + destinationFilePath + '. Error:"' + getLastErrorStringEx();
      ErrorLog(StrBuf);
    end;

    var muayeneResimNo := pUploadDataModule.GetImageCountByMuayeneId(UploadWorkerData.muayeneID) + 1;
    pUploadDataModule.InsertPdfReport(baseFile, UploadWorkerData.muayeneID, UploadWorkerData.eyePosition, muayeneResimNo);

  except
    on E: Exception do begin
      ErrorLog('TUploadManager.ImportPdfReport: Error while copying pdf report! From:' + sourceFilePath + '; TO:' + destinationFilePath + '. Error:"' + E.Message);
    end;
  end;
end;

procedure TUploadManager.Execute;
const
  UPLOAD_MANAGER_SLEEP_TIME_MS = 10*1000; //10seconds
var
  createAnalysisRequestDTO: TCreateAnalysisRequestDTO;
  createAnalysisResponse: TCreateAnalysisResponseDTO;
  uploadImage: TUploadImage;
  NotAnalysedImages: TList<TNotAnalysedImageDTO>;
begin
  while not Terminated do begin

    CleanFinishedWorkers;

    try
      NotAnalysedImages := pUploadDataModule.GetNotAnalysedImageList(imageDir);
      try
        for var i := 0 to NotAnalysedImages.Count-1 do begin
          var NotAnalysedImageDTO := NotAnalysedImages[i];

          var UploadWorker := TUploadWorker.Create;
          UploadWorker.OnSuccessWorkFinished := UploadWorkerSuccessFinishedHandler;
          UploadWorker.OnFailureWorkFinished := UploadWorkerFailureFinishedHandler;
          FUploadWorkers.Add(UploadWorker);

          createAnalysisRequestDTO := NotAnalysedImageDTO.toTCreateAnalysisRequestDTO();

          createAnalysisResponse := FApiWrapper.createAnalysis(createAnalysisRequestDTO);
          if createAnalysisResponse = Nil then begin
            ErrorLog('TUploadManager.Start: Creating analysis failed. Exiting...');
            pUploadDataModule.CreateOrUpdateAnalysis('NO GUID', NotAnalysedImageDTO.muayeneId, NotAnalysedImageDTO.imageId, ERROR_WHILE_CREATING_OCT_ANALYSIS);
            DestroyUploadWorker(UploadWorker);
            continue;
          end;

          pUploadDataModule.CreatePendingAnalysis(createAnalysisResponse.guid, NotAnalysedImageDTO.muayeneId, NotAnalysedImageDTO.imageId);

          UploadWorker.AnalysisGuid := createAnalysisResponse.guid;
          UploadWorker.JwtToken := createAnalysisResponse.jwtToken;
          UploadWorker.MuayeneID := NotAnalysedImageDTO.muayeneId;
          UploadWorker.HastaID := NotAnalysedImageDTO.hastaId;
          UploadWorker.ImageID := NotAnalysedImageDTO.imageId;
          UploadWorker.eyePosition := NotAnalysedImageDTO.eyePosition;

          // enqueue images
          for var j := 0 to Length(createAnalysisResponse.presignedUrls) - 1 do begin
            uploadImage := TUploadImage.Create;
            uploadImage.presignedURL := createAnalysisResponse.presignedUrls[j];
            var fileName := GetFileNameByIndexInFolder(NotAnalysedImageDTO.octFolderPath, j);
            uploadImage.imageFilePath := NotAnalysedImageDTO.octFolderPath + PathDelim + fileName;
            UploadWorker.EnqueueUploadImage(uploadImage);
          end;

          FreeAndNil(createAnalysisResponse);
          FreeAndNil(createAnalysisRequestDTO);

          UploadWorker.Start;
        end;
      finally
        for var item in NotAnalysedImages do item.Free;
        NotAnalysedImages.Free;
      end;
    Except
      on E: Exception do begin
        ErrorLog('TUploadManager.Start: Error: ' + E.Message);
      end;
    end;

    Sleep(UPLOAD_MANAGER_SLEEP_TIME_MS);

  end;
end;

procedure TUploadManager.UploadWorkerSuccessFinishedHandler(Sender: TObject; UploadWorkerData: TUploadWorkerData);
begin
  try
    //Start Analysis
    if FApiWrapper.StartAnalysis(UploadWorkerData.jwtToken, UploadWorkerData.analysisGuid) then begin
      pUploadDataModule.markImageAsAnalysed(UploadWorkerData.imageID);
      GetAnalysis(UploadWorkerData);
    end
    else begin
      ErrorLog('TUploadManager.UploadWorkerSuccessFinishedHandler : Error while starting analysis : ' + UploadWorkerData.analysisGuid);
      pUploadDataModule.CreateOrUpdateAnalysis(UploadWorkerData.analysisGuid, UploadWorkerData.muayeneID, UploadWorkerData.imageID, ERROR_WHILE_STARTING_OCT_ANALYSIS);
    end;
  Except
    on E: Exception do begin
      ErrorLog('TUploadManager.UploadWorkerSuccessFinishedHandler: Error: ' + E.Message );
    end;
  End;
end;

procedure TUploadManager.UploadWorkerFailureFinishedHandler(Sender: TObject; UploadWorkerData: TUploadWorkerData);
begin
  try
    pUploadDataModule.CreateOrUpdateAnalysis(UploadWorkerData.analysisGuid, UploadWorkerData.muayeneID, UploadWorkerData.imageID, NO_IMAGE_UPLOADED_TO_S3);
  Except
    on E: Exception do begin
      ErrorLog('TUploadManager.UploadWorkerFailureFinishedHandler: Error: ' + E.Message );
    end;
  end;
end;

procedure TUploadManager.setAnomalies(anomalies: TArray<String>; UploadWorkerData: TUploadWorkerData);
var
  anomaly: String;
begin
  try
    pUploadDataModule.DeleteAllRecordsOfHastaHastalik(UploadWorkerData.hastaID, UploadWorkerData.muayeneID, UploadWorkerData.eyePosition);

    for anomaly in anomalies do begin
      var hastalikId := pUploadDataModule.GetOrInsertHastalik(anomaly);
      var hastaHastalik := THastaHastalik.Create;
      try
        hastaHastalik.hastaId := UploadWorkerData.hastaID;
        hastaHastalik.hastalikId := hastalikId;
        hastaHastalik.muayeneId := UploadWorkerData.muayeneID;
        hastaHastalik.rightLeft := UploadWorkerData.eyePosition;
        hastaHastalik.hastalikTime := Now();
        hastaHastalik.hastalikScore := 1; //no score comes from detection
        pUploadDataModule.AddPatientDiagnosis(hastaHastalik);
      finally
        FreeAndNil(hastaHastalik);
      end;
    end;
  Except
    on E: Exception do
      ErrorLog('TUploadManager.setAnomalies: Error: Couldnt add new anomalies from getAnalysis endpoint to tblHastalik correctly. ' + E.Message );
  End;
end;

function TUploadManager.setHtmlTemplateDict(muayeneId: Integer): TDictionary<String, String>;
const
  AVERAGE_NUMBER_OF_DAYS_IN_A_YEAR = 365.25;
  FREESANS_TTF = 'FreeSans.ttf';
var
  htmlTemplateDict : TDictionary<String, String>;
  fontFamilyPath: String;
  hasta: THasta;
begin
  Result := nil;
  hasta := nil;
  try
    try
      htmlTemplateDict := TDictionary<String, String>.Create;

      // Font Family Path
      fontFamilyPath := GetFontFamilyPath(FREESANS_TTF);
      if not fontFamilyPath.IsEmpty then begin
        htmlTemplateDict.Add('#fontFamilyPath#', fontFamilyPath);
      end;

      hasta := pUploadDataModule.GetHastaByMuayeneId(muayeneId);
      if Assigned(hasta) then begin
        // Performing Physician
        htmlTemplateDict.Add('#performingPhysician#', pUploadDataModule.GetPhysicianNameSurname(hasta.doctorId));

        // Patient Name
        htmlTemplateDict.Add('#patientName#', hasta.hastaAdi+' '+hasta.hastaSoyadi);

        // Protocol No
        htmlTemplateDict.Add('#protocolNo#', hasta.hastaNumarasi);
      end;

      Result := htmlTemplateDict;
    finally
      FreeAndNil(hasta);
    end;
  Except
    on E: Exception do
      ErrorLog('TUploadManager.setHtmlTemplateDict: Error: ' + E.Message );
  End;
end;

function TUploadManager.LoadPdfReport(UploadWorkerData: TUploadWorkerData): Boolean;
var
  pdfReportTempPath, htmlReportTempPath, baseUrl: string;
  isFileConvertedSuccessfully: Boolean;
begin
  Result := False;

  try
    htmlReportTempPath := GetTemporaryFolderPath +'\'+ UploadWorkerData.analysisGuid + '.html';
    pdfReportTempPath := GetTemporaryFolderPath +'\'+ UploadWorkerData.analysisGuid + '.pdf';

    // Get html report from backend and save it to temp folder
    baseUrl := FOCTSettingsManager.ApiUrl + '/api/pdfGenerator/getOctHtmlReport';
    SaveRawHtmlReportToTempFolder(UploadWorkerData.jwtToken,
                                  baseUrl,
                                  htmlReportTempPath,
                                  UploadWorkerData.analysisGuid);

    // Replace patient KVKK related template with real values and overwrite the existing html template file
    if not FileExists(htmlReportTempPath) then begin
      ErrorLog('TUploadDataModule.LoadPdfReport: Error while saving html report. Report doesn''t exist');
      pUploadDataModule.CreateOrUpdateAnalysis(UploadWorkerData.analysisGuid, UploadWorkerData.muayeneID, UploadWorkerData.imageID, ERROR_WHILE_GETTING_OCT_HTML_REPORT);
      exit;
    end;
    SaveChangedHtmlReportToTempFolder(htmlReportTempPath, setHtmlTemplateDict(UploadWorkerData.muayeneID));

    // Convert html to pdf using wkhtmltopdf.exe
    isFileConvertedSuccessfully := SaveConvertedPdfReportToTempFolder(htmlReportTempPath, pdfReportTempPath);
    if not isFileConvertedSuccessfully then begin
      ErrorLog('TUploadDataModule.LoadPdfReport: Error while converting html report to pdf.');
      pUploadDataModule.CreateOrUpdateAnalysis(UploadWorkerData.analysisGuid, UploadWorkerData.muayeneID, UploadWorkerData.imageID, ERROR_WHILE_CONVERTING_OCT_HTML_REPORT_TO_PDF);
      exit;
    end;

    ImportPdfReport(pdfReportTempPath, UploadWorkerData);
    Result := True;
  except
    on E: Exception do begin
      ErrorLog(EC_404 + ' TUploadDataModule.LoadPdfReport: Error loading pdf report. ' + E.Message + sLineBreak + RA_404);
      FApiWrapper.sendClientLog(ERROR, EC_404 + ' Error loading pdf report. ' + E.Message + ' ' + RA_404);
    end;
  end;
end;

end.

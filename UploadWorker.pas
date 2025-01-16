unit UploadWorker;

interface

uses
  System.Classes, System.Generics.Collections, System.SyncObjs, System.Net.HttpClientComponent,
  System.SysUtils, System.Net.HttpClient, DTO;

type
  TWorkFinishedEvent = procedure(Sender: TObject; UploadWorkerData: TUploadWorkerData) of object;
  TUploadWorker = class(TThread)
  private
    FUploadImageList: TList<TUploadImage>;
    FOnSuccessWorkFinished: TWorkFinishedEvent;
    FOnFailureWorkFinished: TWorkFinishedEvent;
    FAnalysisGuid: String;
    FJwtToken: String;
    FMuayeneID: Integer;
    FHastaID: Integer;
    FImageID: Integer;
    FIsActive: Boolean;
    FEyePosition: Integer;
  protected
    procedure Execute; override;
    function SendFileWithPUT(const URL, FileName: string): Integer;
  public
    constructor Create;
    procedure EnqueueUploadImage(const uploadImage: TUploadImage);
    property OnSuccessWorkFinished: TWorkFinishedEvent read FOnSuccessWorkFinished write FOnSuccessWorkFinished;
    property OnFailureWorkFinished: TWorkFinishedEvent read FOnFailureWorkFinished write FOnFailureWorkFinished;
    property AnalysisGuid: String read FAnalysisGuid write FAnalysisGuid;
    property JwtToken: String read FJwtToken write FJwtToken;
    property muayeneID: Integer read FMuayeneID write FMuayeneID;
    property hastaID: Integer read FHastaID write FHastaID;
    property imageID: Integer read FImageID write FImageID;
    property isActive: Boolean read FIsActive write FIsActive;
    property eyePosition: Integer read FEyePosition write FEyePosition;
    property UploadImageList: TList<TUploadImage> read FUploadImageList write FUploadImageList;
  end;

implementation

uses BasicLogger, UploadDataModule;

constructor TUploadWorker.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False; //upload manager frees finished workers
  FUploadImageList := TList<TUploadImage>.Create;
end;

procedure TUploadWorker.EnqueueUploadImage(const uploadImage: TUploadImage);
begin
  FUploadImageList.Add(uploadImage);
end;

function TUploadWorker.SendFileWithPUT(const URL, FileName: string): Integer;
var
  HttpClient: TNetHTTPClient;
  FileStream: TFileStream;
  response: IHTTPResponse;
begin
  Result := 0;
  HttpClient := nil;
  FileStream := nil;

  try
    try
      HttpClient := TNetHTTPClient.Create(nil);
      FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);

      HttpClient.CustomHeaders['Authorization'] := 'Bearer dummy'; //aws function just checks for existence of this header
      HttpClient.CustomHeaders['x-amz-acl'] := 'bucket-owner-full-control'; //hack to have accessible aws s3 file permissions

      response := HttpClient.Put(URL, FileStream);
      Result := response.StatusCode;
    Except
      on E: Exception do begin
        ErrorLog(EC_101 + ' TUploadWorker.SendFileWithPUT: Error while uploading image to S3: ' + E.Message + sLineBreak + RA_101);
      end;
    end;
  finally
    FileStream.Free;
    HttpClient.Free;   
  end;
end;

procedure TUploadWorker.Execute;
var
  responseCode: Integer;
  UploadWorkerData: TUploadWorkerData;
begin
  UploadWorkerData := nil;

  try
    var errorOccured := False;
    for var uploadedImageInfo in FUploadImageList do begin
      responseCode := SendFileWithPUT(uploadedImageInfo.presignedURL, uploadedImageInfo.imageFilePath);
      if responseCode = 200 then begin
        ErrorLog('TUploadWorker.Execute: Image uploaded successfully: ' + uploadedImageInfo.ImageFilePath);
      end
      else begin
        errorOccured := True;
        ErrorLog('TUploadWorker.Execute: Image upload failed. StatusCode: ' + IntToStr(responseCode));
        break;
      end;
    end;

    UploadWorkerData := TUploadWorkerData.Create;
    UploadWorkerData.analysisGuid := FAnalysisGuid;
    UploadWorkerData.jwtToken := FJwtToken;
    UploadWorkerData.muayeneID := FMuayeneID;
    UploadWorkerData.hastaID := FHastaID;
    UploadWorkerData.imageID := FImageID;
    UploadWorkerData.eyePosition := FEyePosition;

    if not errorOccured then begin
      if Assigned(FOnSuccessWorkFinished) then begin
        FOnSuccessWorkFinished(Self, uploadWorkerData);
      end;
    end else begin
      if Assigned(FOnFailureWorkFinished) then begin
        FOnFailureWorkFinished(Self, uploadWorkerData);
      end;
    end;
  finally
    for var item in FUploadImageList do item.Free;
    FUploadImageList.Free;
    FreeAndNil(UploadWorkerData);
  end;
end;

end.


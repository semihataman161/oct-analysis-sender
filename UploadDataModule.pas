unit UploadDataModule;
{$include defines.inc}

interface

uses
  System.SysUtils, System.Classes, ZDataset, Vcl.ExtCtrls, Data.DB,
  ZAbstractTable, ZAbstractRODataset, ZAbstractDataset, ZSqlProcessor, DTO,
  ZAbstractConnection, ZConnection, WorklistFindResult, EcuImageType,
  System.Generics.Collections, QueueStatus, FileUtil, System.SyncObjs;

const
  OCT_REPORT = 'OCT Report';

var
  ConnectionCriticalSection: TCriticalSection; // guard public functions

type
  TUploadDataModule = class(TDataModule)
    ZConnection1: TZConnection;
    bufferBatch: TZSQLProcessor;
    qryNotAnalysedHasta: TZQuery;
    srcHasta: TDataSource;
    srcMuayene: TDataSource;
    qryNotAnalysedHastahasta_numarasi: TWideStringField;
    qryNotAnalysedHastahasta_adi: TWideStringField;
    qryNotAnalysedHastahasta_soyadi: TWideStringField;
    qryNotAnalysedHastahasta_birthday: TDateField;
    qryNotAnalysedHastahas_diabetes: TSmallintField;
    qryNotAnalysedHastahasta_ID: TLongWordField;
    qryNotAnalysedHastahasta_status: TSmallintField;
    qryNotAnalysedHastapatient_ID_issuer: TWideStringField;
    qryNotAnalysedHastadoctor_ID: TLongWordField;
    qryNotAnalysedHastahasta_sex: TWideStringField;
    qryNotAnalysedHastahasta_telefonu: TWideStringField;
    qryNotAnalysedHastahasta_adres1: TWideStringField;
    qryNotAnalysedHastahasta_not: TWideStringField;
    qryNotAnalysedHastahasta_kayityeri: TIntegerField;
    qryNotAnalysedHastareferring_doctor_ID: TLongWordField;
    qryNotAnalysedHastagrp1: TLongWordField;
    qryNotAnalysedHastagrp2: TLongWordField;
    qryNotAnalysedHastagrp3: TWideStringField;
    qryNotAnalysedHastagrp4: TWideStringField;
    qryNotAnalysedHastahasta_deleted: TDateField;
    qryNotAnalysedHastapatient_middle_names: TWideStringField;
    qryNotAnalysedHastapatient_prefixes: TWideStringField;
    qryNotAnalysedHastapatient_suffixes: TWideStringField;
    qryNotAnalysedHastaaccession_number: TWideStringField;
    qryNotAnalysedHastahasta_last_study_ID: TIntegerField;
    qryNotAnalysedHastahasta_tarihi: TDateTimeField;
    srcPhysician: TDataSource;
    qryPhysician: TZQuery;
    qryPhysiciandoctor_ID: TIntegerField;
    qryPhysicianuser_name: TWideStringField;
    qryPhysicianaccount_expires: TDateField;
    qryPhysicianchange_pw: TWideStringField;
    qryPhotographer: TZQuery;
    srcPhotographer: TDataSource;
    qryPhysicianuser_pw: TWideStringField;
    qryPhysicianreal_name: TWideStringField;
    qryPhysicianreal_surname: TWideStringField;
    qryPhotographerphotographer_ID: TIntegerField;
    qryPhotographerphotographer_name: TWideStringField;
    qryNotAnalysedImage: TZQuery;
    srcImage: TDataSource;
    qryNotAnalysedImageimage_ID: TLongWordField;
    qryNotAnalysedImagemuayene_ID: TLongWordField;
    qryNotAnalysedImageinstance_UID: TWideStringField;
    qryNotAnalysedImageimage_right_left: TLongWordField;
    qryNotAnalysedImagemuayene_resim_no: TSmallintField;
    qryNotAnalysedImageimage_name: TWideStringField;
    qryNotAnalysedImageimage_path: TWideStringField;
    qryNotAnalysedImageimage_note: TWideStringField;
    qryNotAnalysedImageimage_time: TDateTimeField;
    qryNotAnalysedImageimage_type: TSmallintField;
    qryNotAnalysedImageselectimg: TSmallintField;
    qryNotAnalysedImageANNOTATIONS: TWideMemoField;
    qryNotAnalysedImageimage_status: TSmallintField;
    qryNotAnalysedImagegrp1: TLongWordField;
    qryNotAnalysedImagegrp2: TWideStringField;
    qryNotAnalysedImageimage_deleted: TDateField;
    qryNotAnalysedImagepredictions: TWideMemoField;
    qryNotAnalysedImagecentered_object: TWideMemoField;
    qryNotAnalysedImagecapture_type: TSmallintField;
    qryAnalysisQueue: TZQuery;
    srcAnalysisQueue: TDataSource;
    qryAnalysisQueuequeue_id: TLongWordField;
    qryAnalysisQueuediagnosis_guid: TWideStringField;
    qryAnalysisQueuequeue_date: TDateTimeField;
    qryAnalysisQueuemuayene_id: TLongWordField;
    qryAnalysisQueueis_completed: TSmallintField;
    qryAnalysisQueuequeue_complete_date: TDateTimeField;
    qryNotAnalysedImageframe_count: TIntegerField;
    qryBuffer: TZQuery;
    qryHastalik: TZQuery;
    qryHastalikID: TLargeintField;
    qryHastalikDESCR: TWideStringField;
    srcHastalik: TDataSource;
    qryMuayeneHastaHastalikR: TZQuery;
    qryMuayeneHastaHastalikL: TZQuery;
    srcMuayeneHastaHastalikL: TDataSource;
    srcMuayeneHastaHastalikR: TDataSource;
    qryMuayeneHastaHastalikLHASTA_ID: TLargeintField;
    qryMuayeneHastaHastalikLHASTALIK_ID: TLargeintField;
    qryMuayeneHastaHastalikLmuayene_ID: TLongWordField;
    qryMuayeneHastaHastalikLright_left: TSmallintField;
    qryMuayeneHastaHastalikLhastalik_time: TDateTimeField;
    qryMuayeneHastaHastalikLhastalik_notes: TWideStringField;
    qryMuayeneHastaHastalikLhastalik_score: TFloatField;
    qryMuayeneHastaHastalikLgrp2: TWideStringField;
    qryMuayeneHastaHastalikRHASTA_ID: TLargeintField;
    qryMuayeneHastaHastalikRHASTALIK_ID: TLargeintField;
    qryMuayeneHastaHastalikRmuayene_ID: TLongWordField;
    qryMuayeneHastaHastalikRright_left: TSmallintField;
    qryMuayeneHastaHastalikRhastalik_time: TDateTimeField;
    qryMuayeneHastaHastalikRhastalik_notes: TWideStringField;
    qryMuayeneHastaHastalikRhastalik_score: TFloatField;
    qryMuayeneHastaHastalikRgrp2: TWideStringField;
    qryAnalysisQueuequeue_status: TWideStringField;
    qryNotAnalysedImageprediction_size: TIntegerField;
    qryHastalikHASTALIK: TWideStringField;
    qryAnalysisQueueoct_image_id: TLongWordField;
    qryNotAnalysedImagehasta_numarasi: TWideStringField;
    qryNotAnalysedImagehasta_adi: TWideStringField;
    qryNotAnalysedImagehasta_soyadi: TWideStringField;
    qryNotAnalysedImagephysician: TWideStringField;
    qryNotAnalysedImagephotographer: TWideStringField;
    qryNotAnalysedImagehasta_birthday: TDateField;
    qryNotAnalysedImagehas_diabetes: TSmallintField;
    tblImage: TZTable;
    srcTblImage: TDataSource;
    tblImageimage_ID: TLongWordField;
    tblImagemuayene_ID: TLongWordField;
    tblImageinstance_UID: TWideStringField;
    tblImageimage_right_left: TLongWordField;
    tblImagemuayene_resim_no: TSmallintField;
    tblImageimage_name: TWideStringField;
    tblImageimage_path: TWideStringField;
    tblImageimage_note: TWideStringField;
    tblImageimage_time: TDateTimeField;
    tblImageANNOTATIONS: TWideMemoField;
    tblImageimage_type: TSmallintField;
    qryPhysicianuser_status: TShortintField;
    qryNotAnalysedImagehasta_ID: TLongWordField;
    procedure ZConnection1BeforeConnect(Sender: TObject);
  private
    { Private declarations }
    procedure AddPatientDiagnosisLeft(hastaHastalik: THastaHastalik);
    procedure AddPatientDiagnosisRight(hastaHastalik: THastaHastalik);
    function GetUTF16ColumnContentSizeInBytes(ColumnName: String): Integer;
    function ReloadTables: Boolean;
    procedure DisConnectDatabase;

  public
    { Public declarations }
    destructor Destroy; override;
    function ConnectDatabaseMain: Boolean;
    procedure CreatePendingAnalysis(analysisGuid: string; muayeneId: Integer; octImageId: Integer);
    procedure CreateOrUpdateAnalysis(analysisGuid: string; muayeneId: Integer; octImageId: Integer; queueStatus: TQueueStatus);
    procedure UpdateImagePredictions(Prediction: String; ImageID: Integer);
    procedure SetQueueStatusCompleted(analysisGuid: String; queueStatus: TQueueStatus);
    procedure AddPatientDiagnosis(hastaHastalik: THastaHastalik);
    procedure DeleteAllRecordsOfHastaHastalik(hastaId: Integer; muayeneId: Integer; eyePosition: Integer);
    procedure InsertPdfReport(baseFile: String; muayeneId: Integer; eyePosition: Integer; muayeneResimNo: Integer);
    function GetNotAnalysedImageList(imageDir: String): TList<TNotAnalysedImageDTO>;
    procedure markImageAsAnalysed(imageId: Integer);
    function GetOrInsertHastalik(description: String): Integer;
    function GetPhysicianNameSurname(doctorId: Integer): String;
    function GetHastaByHastaId(hastaId: Integer): THasta;
    function GetHastaByMuayeneId(muayeneId: Integer): THasta;
    function GetHastaIdByMuayeneId(muayeneId: Integer): Integer;
    function GetImageCountByMuayeneId(muayeneId: Integer): Integer;
    function GetMuayeneByMuayeneId(muayeneId: Integer): TMuayene;
  end;

  // 20111202; Rym: Image active/deleted status now is populated also with N/Exported status
  function dbItemIsActive(  Const ItemStatus: Byte ): boolean;
  function dbItemIsDeleted( Const ItemStatus: Byte ): boolean;
  function deleteDbItemMask( Const ItemStatus: Byte ): byte;
  function UnDeleteDbItemMask( Const ItemStatus: Byte ): byte;
  function dbItemIsExported(  Const ItemStatus: Byte ): boolean;
  function mysql_real_escape_string(const unescaped_string : string ) : string;

Const
  ITEM_STATUS_ACTIVE   = $0;
  ITEM_STATUS_DELETED  = $1;
  ITEM_STATUS_EXPORTED = $2;
  ITEM_STATUS_SYNCHRONIZED = $4;

  ANALYSIS_PENDING = 0;
  ANALYSIS_COMPLETED = 1;

  EYE_POSITION_UNKNOWN = 0;
  EYE_POSITION_LEFT  = 1;
  EYE_POSITION_RIGHT = 2;

var
  pUploadDataModule: TUploadDataModule;
  mySqlHost: String;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses BasicLogger, VCL.Dialogs, System.Variants,
    System.StrUtils;

{$R *.dfm}

procedure TUploadDataModule.AddPatientDiagnosis(hastaHastalik: THastaHastalik);
begin
  ConnectionCriticalSection.Enter;
  try
    try
      if hastaHastalik.rightLeft = EYE_POSITION_LEFT then begin
        try
          AddPatientDiagnosisLeft(hastaHastalik);
        finally
          qryMuayeneHastaHastalikL.EnableControls;
        end;
      end
      else if hastaHastalik.rightLeft = EYE_POSITION_RIGHT then begin
        try
          AddPatientDiagnosisRight(hastaHastalik);
        finally
          qryMuayeneHastaHastalikR.EnableControls;
        end;
      end;
    Except
      on E: Exception do
      ErrorLog('TUploadDataModule.AddPatientDiagnosis: Error while adding patient diagnosis: ' + E.Message
                + 'Diagnosis ID: ' + hastaHastalik.hastalikId.ToString
                + 'Eye Position: ' + hastaHastalik.rightLeft.ToString
                + 'Score: ' + hastaHastalik.hastalikScore.ToString
              );
    end;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

//dont guard private methods with critical section
procedure TUploadDataModule.AddPatientDiagnosisLeft(hastaHastalik: THastaHastalik);
begin
  try
    qryMuayeneHastaHastalikL.Close;
    qryMuayeneHastaHastalikL.ParamByName('muayene_ID').AsInteger := hastaHastalik.muayeneId;
    qryMuayeneHastaHastalikL.Open;
    qryMuayeneHastaHastalikL.Insert;
    qryMuayeneHastaHastalikL.Edit;
    qryMuayeneHastaHastalikLHASTA_ID.AsInteger := hastaHastalik.hastaId;
    qryMuayeneHastaHastalikLHASTALIK_ID.AsInteger := hastaHastalik.hastalikId;
    qryMuayeneHastaHastalikLmuayene_ID.AsInteger := hastaHastalik.muayeneId;
    qryMuayeneHastaHastalikLright_left.AsInteger := hastaHastalik.rightLeft;
    qryMuayeneHastaHastalikLhastalik_time.AsDateTime := hastaHastalik.hastalikTime;
    qryMuayeneHastaHastalikLhastalik_score.AsFloat := hastaHastalik.hastalikScore;
    qryMuayeneHastaHastalikL.Post;
  Except
    on E: Exception do
      ErrorLog('TUploadDataModule.AddPatientDiagnosisLeft: HASTALIK_ID =  ' + InttoStr(hastaHastalik.hastalikId) + '. Error: ' + E.Message);
  end;
end;

//dont guard private methods with critical section
procedure TUploadDataModule.AddPatientDiagnosisRight(hastaHastalik: THastaHastalik);
begin
  try
    qryMuayeneHastaHastalikR.ParamByName('muayene_ID').AsInteger := hastaHastalik.muayeneId;
    qryMuayeneHastaHastalikR.Insert;
    qryMuayeneHastaHastalikR.Edit;
    qryMuayeneHastaHastalikRHASTA_ID.AsInteger := hastaHastalik.hastaId;
    qryMuayeneHastaHastalikRHASTALIK_ID.AsInteger := hastaHastalik.hastalikId;
    qryMuayeneHastaHastalikRmuayene_ID.AsInteger := hastaHastalik.muayeneId;
    qryMuayeneHastaHastalikRright_left.AsInteger := hastaHastalik.rightLeft;
    qryMuayeneHastaHastalikRhastalik_time.AsDateTime := NOW();
    qryMuayeneHastaHastalikRhastalik_score.AsFloat := hastaHastalik.hastalikScore;
    qryMuayeneHastaHastalikR.Post;
  Except
    on E: Exception do
      ErrorLog('TUploadDataModule.AddPatientDiagnosisRight: HASTALIK_ID =  ' + InttoStr(hastaHastalik.hastalikId) + '. Error: ' + E.Message);
  end;
end;

function TUploadDataModule.GetUTF16ColumnContentSizeInBytes(ColumnName: String): Integer;
begin
  Result := 0;
  try
    var columnContent := qryBuffer.FindField(columnName).AsString;
    Result := Length(columnContent) * SizeOf(Char);
  Except
    on E: Exception do
      ErrorLog('TUploadDataModule..GetColumnSizeInBytes: ColumnName: ' + ColumnName + ' Error: ' + E.Message);
  end;
end;

procedure TUploadDataModule.InsertPdfReport(baseFile: String; muayeneId: Integer; eyePosition: Integer; muayeneResimNo: Integer);
begin
  ConnectionCriticalSection.Enter;
  try
    tblImage.Close;
    tblImage.Open;
    tblImage.Insert;
    tblImagemuayene_ID.AsInteger := muayeneId;
    tblImageimage_right_left.AsInteger := eyePosition;
    tblImageimage_name.AsString := OCT_REPORT;
    tblImageimage_note.AsString := ' ';
    tblImageimage_path.AsString := baseFile;
    tblImageimage_time.AsDateTime := Now();
    tblImageimage_type.AsInteger := Ord(ecuImageTypeReportOct);
    tblImagemuayene_resim_no.AsInteger := muayeneResimNo;
    tblImage.Post;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

procedure TUploadDataModule.markImageAsAnalysed(imageId: Integer);
begin
  ConnectionCriticalSection.Enter;
  try

    try
      qryBuffer.sql.text :=
      'UPDATE b_image SET image_note = CONCAT(COALESCE(image_note,""),":*")'
      +' WHERE image_ID = :imageId AND COALESCE(image_note,"") NOT LIKE "%*%"';
      qryBuffer.ParamByName('imageId').AsInteger := imageId;
      qryBuffer.ExecSQL;
    Except
      on E: Exception do begin
        ErrorLog('TDataModule1.DeleteAllRecordsOfHastaHastalik: Error while deleting all records of HastaHastalik: ' + E.Message);
      end;
    end;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

function TUploadDataModule.ConnectDatabaseMain: Boolean;
begin
  // Handle connection settings
  ZConnection1.Connected := false;
  ZConnection1.HostName := mySqlHost;
  qryNotAnalysedHasta.active := false;

  Try
    ZConnection1.Connect();
    qryNotAnalysedHasta.Open();
    qryNotAnalysedImage.Open();
    qryPhysician.Open();
    qryPhotographer.Open();
    qryAnalysisQueue.Open();
    qryHastalik.Open();
    qryMuayeneHastaHastalikR.Open();
    qryMuayeneHastaHastalikL.Open();
    Result := True;
    ErrorLog('TUploadDataModule.ConnectDatabaseMain: MySQL connection established!');
  Except
    on E: Exception do begin
        Result := False;
        ErrorLog('Error connecting database. ' + E.Message + '. Host name was: ' + mySqlHost);
    end;
  End;
end;

procedure TUploadDataModule.ZConnection1BeforeConnect(Sender: TObject);
begin
  ZConnection1.LibraryLocation := ''; // ExtractFileDir(ParamStr(0));
end;

procedure TUploadDataModule.CreatePendingAnalysis(analysisGuid: string; muayeneId: Integer; octImageId: Integer);
begin
  ConnectionCriticalSection.Enter;
  try
    qryAnalysisQueue.Close;
    qryAnalysisQueue.ParamByName('muayene_ID').AsInteger := muayeneId;
    qryAnalysisQueue.Open;
    if qryAnalysisQueue.Locate('diagnosis_guid', analysisGuid, [LoCaseInsensitive]) then
    begin
      qryAnalysisQueue.Edit;
    end
    else begin
      qryAnalysisQueue.Insert;
    end;

    qryAnalysisQueuediagnosis_guid.AsString := analysisGuid;
    qryAnalysisQueuemuayene_id.AsInteger := muayeneId;
    qryAnalysisQueuequeue_date.AsDateTime := Now();
    qryAnalysisQueueoct_image_id.AsInteger := octImageId;
    qryAnalysisQueue.Post;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

procedure TUploadDataModule.CreateOrUpdateAnalysis(analysisGuid: string; muayeneId, octImageId: Integer; queueStatus: TQueueStatus);
begin
  ConnectionCriticalSection.Enter;
  try
    qryAnalysisQueue.Close;
    qryAnalysisQueue.ParamByName('muayene_ID').AsInteger := muayeneId;
    qryAnalysisQueue.Open;
    if qryAnalysisQueue.Locate('diagnosis_guid', analysisGuid, [LoCaseInsensitive]) then
    begin
      qryAnalysisQueue.Edit;
    end
    else begin
      qryAnalysisQueue.Insert;
    end;

    qryAnalysisQueuediagnosis_guid.AsString := analysisGuid;
    qryAnalysisQueuemuayene_id.AsInteger := muayeneId;
    qryAnalysisQueuequeue_date.AsDateTime := Now();
    qryAnalysisQueueoct_image_id.AsInteger := octImageId;
    qryAnalysisQueuequeue_status.AsString := queueStatus;
    qryAnalysisQueuequeue_complete_date.AsDateTime := Now();
    qryAnalysisQueue.Post;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

procedure TUploadDataModule.DeleteAllRecordsOfHastaHastalik(hastaId: Integer; muayeneId: Integer; eyePosition: Integer);
begin
  ConnectionCriticalSection.Enter;
  try
    try
      qryBuffer.sql.text := 'DELETE FROM hasta_hastalik WHERE HASTA_ID = :hastaId AND muayene_ID = :muayeneId AND right_left = :eyePosition';
      qryBuffer.ParamByName('hastaId').AsInteger := hastaId;
      qryBuffer.ParamByName('muayeneId').AsInteger := muayeneId;
      qryBuffer.ParamByName('eyePosition').AsInteger := eyePosition;
      qryBuffer.ExecSQL;
    Except
      on E: Exception do begin
        ErrorLog('TDataModule1.DeleteAllRecordsOfHastaHastalik: Error while deleting all records of HastaHastalik: ' + E.Message);
      end;
    end;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

destructor TUploadDataModule.Destroy;
begin
  DisConnectDatabase;
  inherited;
end;

procedure TUploadDataModule.DisConnectDatabase;
begin
  Try
    if ZConnection1.Connected then
      ZConnection1.DisConnect();
  Except
  End;
end;

function TUploadDataModule.GetHastaByHastaId(hastaId: Integer): THasta;
begin
  ConnectionCriticalSection.Enter;
  try
    Result := nil;
    try
      qryBuffer.Close;
      qryBuffer.sql.text := 'SELECT * FROM b_hasta WHERE hasta_ID = :hasta_ID';
      qryBuffer.ParamByName('hasta_ID').AsInteger := hastaId;
      qryBuffer.Open;
      if not qryBuffer.IsEmpty then begin
        var hasta := THasta.Create;
        hasta.FHastaId := qryBuffer.FieldByName('hasta_ID').AsInteger;
        hasta.FHastaNumarasi := qryBuffer.FieldByName('hasta_numarasi').AsString;
        hasta.FHastaAdi := qryBuffer.FieldByName('hasta_adi').AsString;
        hasta.FHastaSoyadi := qryBuffer.FieldByName('hasta_soyadi').AsString;
        hasta.FDoctorId := qryBuffer.FieldByName('doctor_ID').AsInteger;
        Result := hasta;
      end;
      qryBuffer.Close;
    Except
      on E: Exception do
        ErrorLog('TUploadDataModule.GetHastaIdByMuayeneId: hastaId: ' + IntToStr(hastaId) + ' Error: ' + E.Message );
    end;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

//convenience function - no need to use critical section lock
function TUploadDataModule.GetHastaByMuayeneId(muayeneId: Integer): THasta;
begin
  var hastaId := GetHastaIdByMuayeneId(muayeneId);
  Result := GetHastaByHastaId(hastaId);
end;

function TUploadDataModule.GetHastaIdByMuayeneId(muayeneId: Integer): Integer;
begin
  ConnectionCriticalSection.Enter;
  try
    Result := 0;
    try
      qryBuffer.Close;
      qryBuffer.sql.text := 'SELECT hasta_ID FROM b_muayene WHERE muayene_ID = :muayeneId';
      qryBuffer.ParamByName('muayeneId').AsInteger := muayeneId;
      qryBuffer.Open;
      if not qryBuffer.IsEmpty then begin
        qryBuffer.First;
        Result := qryBuffer.FieldByName('hasta_ID').AsInteger;
      end;
      qryBuffer.Close;
    Except
      on E: Exception do
        ErrorLog('TUploadDataModule.GetHastaIdByMuayeneId: muayeneId: ' + IntToStr(muayeneId) + ' Error: ' + E.Message );
    end;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

function TUploadDataModule.GetImageCountByMuayeneId(muayeneId: Integer): Integer;
var
  recordCount: Integer;
begin
  ConnectionCriticalSection.Enter;
  try
    Result := 0;
    try
      qryBuffer.Close;
      qryBuffer.sql.text := 'SELECT COUNT(*) FROM b_image WHERE muayene_ID = :muayene_ID';
      qryBuffer.ParamByName('muayene_ID').AsInteger := muayeneId;
      qryBuffer.Open;
      recordCount := qryBuffer.Fields[0].AsInteger;
      Result := recordCount;
      qryBuffer.Close;
    Except
      on E: Exception do
        ErrorLog('TUploadDataModule.GetImageCountByMuayeneId: muayeneId: ' + IntToStr(muayeneId) + ' Error: ' + E.Message );
    end;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

function TUploadDataModule.GetMuayeneByMuayeneId(muayeneId: Integer): TMuayene;
begin
  ConnectionCriticalSection.Enter;
  try
    Result := nil;
    try
      qryBuffer.Close;
      qryBuffer.sql.text := 'SELECT * FROM b_muayene WHERE muayene_ID = :muayene_ID';
      qryBuffer.ParamByName('muayene_ID').AsInteger := muayeneId;
      qryBuffer.Open;
      if not qryBuffer.IsEmpty then begin
        var muayene := TMuayene.Create;
        muayene.FMuayeneId := qryBuffer.FieldByName('muayene_ID').AsInteger;
        muayene.FHastaId := qryBuffer.FieldByName('hasta_ID').AsInteger;
        muayene.FImageCount := qryBuffer.FieldByName('image_count').AsInteger;
        muayene.FMuayeneTarihi := qryBuffer.FieldByName('muayene_tarihi').AsDateTime;
        Result := muayene;
      end;
      qryBuffer.Close;
    Except
      on E: Exception do
        ErrorLog('TUploadDataModule.GetMuayeneByMuayeneId: muayeneId: ' + IntToStr(muayeneId) + ' Error: ' + E.Message );
    end;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

function TUploadDataModule.GetNotAnalysedImageList(imageDir: String): TList<TNotAnalysedImageDTO>;
var
  NotAnalysedImageDTOs: TList<TNotAnalysedImageDTO>;
begin
  Result := nil;

  ConnectionCriticalSection.Enter;
  try
    try
      NotAnalysedImageDTOs := TList<TNotAnalysedImageDTO>.Create;
      Result := NotAnalysedImageDTOs;

      qryNotAnalysedImage.Close;
      qryNotAnalysedImage.Open;
      qryNotAnalysedImage.First;
      while not qryNotAnalysedImage.Eof do begin

          var NotAnalysedImageDTO := TNotAnalysedImageDTO.Create;
          with NotAnalysedImageDTO do begin
            hastaId := qryNotAnalysedImagehasta_ID.AsInteger;
            protocolNo := qryNotAnalysedImagehasta_numarasi.AsString;
            patientName := Copy(qryNotAnalysedImagehasta_adi.AsString, 1, 1);
            patientSurname := Copy(qryNotAnalysedImagehasta_soyadi.AsString, 1, 1);
            hasDiabetes := getHasDiabetesAsBoolean(qryNotAnalysedImagehas_diabetes.AsInteger);
            patientBirthdate := getModifiedPatientBirthDate(qryNotAnalysedImagehasta_birthday.AsDateTime);
            physician := qryNotAnalysedImagephysician.AsString;
            photographer := qryNotAnalysedImagephotographer.AsString;

            eyePosition := qryNotAnalysedImageimage_right_left.AsInteger;
            muayeneId := qryNotAnalysedImagemuayene_ID.AsInteger;
            imageId := qryNotAnalysedImageimage_ID.AsInteger;
            imageCount := qryNotAnalysedImageframe_count.AsInteger;

            octFolderName := qryNotAnalysedImageimage_path.AsString;
            octFolderPath := imageDir + PathDelim + octFolderName;
            var fileExtension := GetFirstFileExtension(octFolderPath);
            commonImageExtension := Copy(fileExtension, 2, Length(fileExtension) - 1);
            commonImagePrefix := octFolderName;
          end;
          NotAnalysedImageDTOs.Add(NotAnalysedImageDTO);
          qryNotAnalysedImage.Next;
      end;
    Except
      on E: Exception do begin
        ErrorLog('TUploadDataModule.GetNotAnalysedImageList: Error: ' + E.Message);
      end;
    end;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

function TUploadDataModule.GetOrInsertHastalik(description: String): Integer;
begin
  Result := 0;

  ConnectionCriticalSection.Enter;
  try
    qryHastalik.Close;
    qryHastalik.Open;
    if not qryHastalik.Locate('DESCR', description, []) then begin
      // Add diagnosis if it doesnt exist
      qryHastalik.Insert;
      qryHastalikDESCR.AsString := description;
      qryHastalikHASTALIK.AsString := description;
      qryHastalik.Post;
    end;
    Result := qryHastalikID.AsInteger;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

function TUploadDataModule.GetPhysicianNameSurname(doctorId: Integer): String;
begin
  ConnectionCriticalSection.Enter;
  try
    Result := '';
    qryPhysician.Close;
    qryPhysician.ParamByName('doctor_ID').AsInteger := doctorId;
    qryPhysician.Open;
    if not qryPhysician.IsEmpty then begin
      qryPhysician.First;
      Result := qryPhysicianreal_name.AsString + ' ' + qryPhysicianreal_surname.AsString;
    end;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

function dbItemIsActive(  Const ItemStatus: Byte ): boolean;
begin
  Result := (ItemStatus and ITEM_STATUS_DELETED) = ITEM_STATUS_ACTIVE;
end;

function dbItemIsDeleted( Const ItemStatus: Byte ): boolean;
begin
  Result := (ItemStatus and ITEM_STATUS_DELETED) = ITEM_STATUS_DELETED;
end;

function deleteDbItemMask( Const ItemStatus: Byte ): byte;
begin
  Result := (ItemStatus or ITEM_STATUS_DELETED);
end;

function UnDeleteDbItemMask( Const ItemStatus: Byte ): byte;
begin
  Result := (ItemStatus and Not(ITEM_STATUS_DELETED));
end;

function dbItemIsExported(  Const ItemStatus: Byte ): boolean;
begin
  Result := (ItemStatus and ITEM_STATUS_EXPORTED) = ITEM_STATUS_EXPORTED;
end;

function TUploadDataModule.ReloadTables: Boolean;
begin
  Result := False;
  try
    qryNotAnalysedHasta.DisableControls;
    qryNotAnalysedHasta.Close;
    qryNotAnalysedHasta.Open;
    qryNotAnalysedHasta.EnableControls;

    qryNotAnalysedImage.DisableControls;
    qryNotAnalysedImage.Close;
    qryNotAnalysedImage.Open;
    qryNotAnalysedImage.EnableControls;

    qryPhysician.DisableControls;
    qryPhysician.Close;
    qryPhysician.Open;
    qryPhysician.EnableControls;

    qryPhotographer.DisableControls;
    qryPhotographer.Close;
    qryPhotographer.Open;
    qryPhotographer.EnableControls;

    qryAnalysisQueue.DisableControls;
    qryAnalysisQueue.Close;
    qryAnalysisQueue.Open;
    qryAnalysisQueue.EnableControls;

    qryHastalik.DisableControls;
    qryHastalik.Close;
    qryHastalik.Open;
    qryHastalik.EnableControls;

    qryMuayeneHastaHastalikR.DisableControls;
    qryMuayeneHastaHastalikR.Close;
    qryMuayeneHastaHastalikR.Open;
    qryMuayeneHastaHastalikR.EnableControls;

    qryMuayeneHastaHastalikL.DisableControls;
    qryMuayeneHastaHastalikL.Close;
    qryMuayeneHastaHastalikL.Open;
    qryMuayeneHastaHastalikL.EnableControls;

    Result := True;
  Except
    on E: Exception do begin
        ErrorLog('TUploadDataModule.ReloadTables: Error realoading tables. '+ E.Message );
    end;
  End;
end;

procedure TUploadDataModule.SetQueueStatusCompleted(analysisGuid: String; queueStatus: TQueueStatus);
begin
  ConnectionCriticalSection.Enter;
  try
    try
      qryBuffer.sql.text :=
        'UPDATE b_queue'
        +' SET queue_status = :queueStatus,'
        +' queue_complete_date = CURRENT_DATE,'
        +' is_completed = :isCompleted'
        +' WHERE diagnosis_guid = :analysisGuid';

      qryBuffer.ParamByName('queueStatus').AsString := queueStatus;
      qryBuffer.ParamByName('analysisGuid').AsString := analysisGuid;
      qryBuffer.ParamByName('isCompleted').AsInteger := ANALYSIS_COMPLETED;

      qryBuffer.ExecSQL;
    Except
      on E: Exception do begin
        ErrorLog('TUploadDataModule.SetQueueStatusCompleted: Error while setting queue status: ' + E.Message);
      end;
    end;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

procedure TUploadDataModule.UpdateImagePredictions(Prediction: String; ImageID: Integer);
begin
  ConnectionCriticalSection.Enter;
  try
    try
      qryBuffer.Close;
      qryBuffer.sql.text := 'SELECT * FROM b_image WHERE image_ID = :image_ID';
      qryBuffer.ParamByName('image_ID').AsInteger := ImageID;
      qryBuffer.Open;

      if qryBuffer.RecordCount > 0 then
      begin
       while not (qryBuffer.FieldByName('predictions').AsString = '') do
        begin
          qryBuffer.Edit;
          qryBuffer.FieldByName('predictions').AsString := '';
          qryBuffer.Post;
        end;

        qryBuffer.Edit;
        qryBuffer.FieldByName('predictions').AsString := Prediction;
        var utf16PredictionSize := GetUTF16ColumnContentSizeInBytes('predictions');
        qryBuffer.FieldByName('prediction_size').AsInteger := utf16PredictionSize;
        qryBuffer.Post;
      end;

      qryBuffer.Close;
    Except
      on E: Exception do
        ErrorLog('TUploadDataModule.UpdateImagePredictions: ImageID: ' + IntToStr(imageID) + ' Error: ' + E.Message );
    end;
  finally
    ConnectionCriticalSection.Leave;
  end;
end;

function StringReplaceExt(const S : string; OldPattern, NewPattern:  array of string; Flags: TReplaceFlags):string;
var
 i : integer;
begin
   Assert(Length(OldPattern)=(Length(NewPattern)));
   Result:=S;
   for  i:= Low(OldPattern) to High(OldPattern) do
    Result:=StringReplace(Result,OldPattern[i], NewPattern[i], Flags);
end;

function mysql_real_escape_string(const unescaped_string : string ) : string;
begin
  Result:=StringReplaceExt(unescaped_string,
    ['\', #39, #34, #0, #10, #13, #26], ['\\','\'#39,'\'#34,'\0','\n','\r','\Z'] ,
    [rfReplaceAll]
  );
end;


initialization
  ConnectionCriticalSection := TCriticalSection.Create;

finalization
  ConnectionCriticalSection.Free;

end.

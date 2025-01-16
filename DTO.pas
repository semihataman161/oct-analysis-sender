unit DTO;

interface

uses System.DateUtils, System.SysUtils, System.Classes;

type
  TImageStatusValue = (GOOD = 0, REJECT = 1, USABLE = 2, TILTED = 3);

  TSendClientLogRequestDTO = class(TObject)
    public
      level:Integer;
      message:String;
      constructor Create();
    end;

  TCreateAnalysisRequestDTO = class(TObject)
    public
      FProtocolNo: String;
      FPatientName: String;
      FPatientSurname: String;
      FPhysician: String;
      FHasDiabetes: Boolean;
      FPatientBirthdate: TDateTime;
      FPhotographer: String;
      FCommonImagePrefix: String;
      FCommonImageExtension: String;
      FImageCount: Integer;
      FEyePosition: Integer;
      property protocolNo: String read FProtocolNo write FProtocolNo;
      property patientName: String read FPatientName write FPatientName;
      property patientSurname: String read FPatientSurname write FPatientSurname;
      property physician: String read FPhysician write FPhysician;
      property hasDiabetes: Boolean read FHasDiabetes write FHasDiabetes;
      property patientBirthdate: TDateTime read FPatientBirthdate write FPatientBirthdate;
      property photographer: String read FPhotographer write FPhotographer;
      property commonImagePrefix: String read FCommonImagePrefix write FCommonImagePrefix;
      property commonImageExtension: String read FCommonImageExtension write FCommonImageExtension;
      property imageCount: Integer read FImageCount write FImageCount;
      property eyePosition: Integer read FEyePosition write FEyePosition;
      function getHasDiabetesAsBoolean(value: Integer): Boolean;
      function getModifiedPatientBirthDate(originalPatientBirthDate: TDateTime): TDateTime;
      constructor Create();
    end;

  TNotAnalysedImageDTO = class(TCreateAnalysisRequestDTO)
    public
      FmuayeneId: Integer;
      FhastaId: Integer;
      FimageId: Integer;
      FoctFolderName: String;
      FoctFolderPath: String;
      property muayeneId: Integer read FmuayeneId write FmuayeneId;
      property hastaId: Integer read FhastaId write FhastaId;
      property imageId: Integer read FimageId write FimageId;
      property octFolderName: String read FoctFolderName write FoctFolderName;
      property octFolderPath: String read FoctFolderPath write FoctFolderPath;
      function toTCreateAnalysisRequestDTO(): TCreateAnalysisRequestDTO;
    end;

  TCreateAnalysisResponseDTO = class(TObject)
    public
      fGuid: String;
      fJwtToken: String;
      fPresignedUrls: TArray<String>;
      property guid: String read fGuid write fGuid;
      property jwtToken: String read fJwtToken write fJwtToken;
      property presignedUrls: TArray<String> read fPresignedUrls write fPresignedUrls;
      constructor create();
    end;

  TPoint = class(TObject)
    public
      fx: Double;
      fy: Double;
      property x: Double read fx write fx;
      property y: Double read fy write fy;
      constructor Create();
    end;

  TDetection = class(TObject)
    public
      FClassId: Integer;
      FClassName : String;
      FFriendlyClassName: String;
      FPoints: TArray<TPoint>;
      property classId : Integer read FClassId write FClassId;
      property className : String read FClassName write FClassName;
      property friendlyClassName : String read FFriendlyClassName write FFriendlyClassName;
      property points: TArray<TPoint> read FPoints write FPoints;
      constructor Create();
      destructor Destroy; override;
    end;

  TLayer = class(TObject)
    public
      FLayerId: Integer;
      FLayerName: String;
      property layerId: Integer read FLayerId write FLayerId;
      property layerName: String read FLayerName write FLayerName;
      constructor Create();
    end;

  TAnomalyLayerDetection = class(TObject)
    public
      FAnomalyId: Integer;
      FAnomalyName: String;
      FLayers: TArray<TLayer>;
      property anomalyId: Integer read FAnomalyId write FAnomalyId;
      property anomalyName: String read FAnomalyName write FAnomalyName;
      property layers: TArray<TLayer> read FLayers write FLayers;
      constructor Create();
      destructor Destroy; override;
    end;

  TAnomalyArea = class(TObject)
    public
      FAnomalyClassId: Integer;
      FAnomalyClassName: String;
      FTotalArea: Double;
      property anomalyClassId: Integer read FAnomalyClassId write FAnomalyClassId;
      property anomalyClassName: String read FAnomalyClassName write FAnomalyClassName;
      property totalArea: Double read FTotalArea write FTotalArea;
    end;

  TImageInformation = class(TObject)
    public
      FImageId: Integer;
      FCompleted: Integer;
      FLocalImageId: Integer;
      FImagePath: String;
      FName: String;
      FUploadedName: String;
      FLayerDetections: TArray<TDetection>;
      FAnomalyDetections: TArray<TDetection>;
      FAnomalyLayerDetections: TArray<TAnomalyLayerDetection>;
      FAnomalyAreas: TArray<TAnomalyArea>;
      FMessage: String;
      property imageId: Integer read FImageId write FImageId;
      property completed: Integer read FCompleted write FCompleted;
      property localImageId: Integer read FLocalImageId write FLocalImageId;
      property imagePath: String read FImagePath write FImagePath;
      property name: String read FName write FName;
      property uploadedName: String read FUploadedName write FUploadedName;
      property layerDetections: TArray<TDetection> read FLayerDetections write FLayerDetections;
      property anomalyDetections: TArray<TDetection> read FAnomalyDetections write FAnomalyDetections;
      property anomalyLayerDetections: TArray<TAnomalyLayerDetection> read FAnomalyLayerDetections write FAnomalyLayerDetections;
      property anomalyAreas: TArray<TAnomalyArea> read FAnomalyAreas write FAnomalyAreas;
      property message: String read FMessage write FMessage;
      constructor Create();
      destructor Destroy; override;
    end;

  TDataResponse = class(TObject)
    public
      Fready: Boolean;
      FImageInfos: TArray<TImageInformation>;
      FFoundAnomalies: TArray<String>;
      property ready: Boolean read Fready write Fready;
      property imageInfos: TArray<TImageInformation> read FImageInfos write FImageInfos;
      property foundAnomalies: TArray<String> read FFoundAnomalies write FFoundAnomalies;
      constructor Create();
      destructor Destroy; override;
    end;

  TAnalysisResponseObj = class(TObject)
    public
      Fsuccess: Boolean;
      Fmessage: String;
      Fdata: TDataResponse;
      property success: Boolean read Fsuccess write Fsuccess;
      property message: String read Fmessage write Fmessage;
      property data: TDataResponse read Fdata write Fdata;
      constructor Create();
      destructor Destroy; override;
    end;

  TUploadImage = class(TObject)
    private
      { Private declarations }
      FPresignedURL: String;
      FImageFilePath: String;
    public
      { Public declarations }
      property presignedURL: String read FPreSignedURL write FPreSignedURL;
      property imageFilePath: String read FImageFilePath write FImageFilePath;
      constructor Create();
    end;

  TUploadWorkerData = class(TObject)
    private
      { Private declarations }
      FAnalysisGuid: String;
      FJwtToken: String;
      FMuayeneID: Integer;
      FImageID: Integer;
      FHastaID: Integer;
      FEyePosition: Integer;
    public
      { Public declarations }
      property analysisGuid: String read FAnalysisGuid write FAnalysisGuid;
      property jwtToken: String read FJwtToken write FJwtToken;
      property muayeneID: Integer read FMuayeneID write FMuayeneID;
      property imageID: Integer read FImageID write FImageID;
      property hastaID: Integer read FHastaID write FHastaID;
      property eyePosition: Integer read FEyePosition write FEyePosition;
      constructor Create();
      function ToString: string; override;
    end;

  THasta = class(TObject)
    public
      FHastaId: Integer;
      FHastaNumarasi: String;
      FHastaAdi: String;
      FHastaSoyadi: String;
      FDoctorId: Integer;
      property hastaId: Integer read FHastaId write FHastaId;
      property hastaNumarasi: String read FHastaNumarasi write FHastaNumarasi;
      property hastaAdi: String read FHastaAdi write FHastaAdi;
      property hastaSoyadi: String read FHastaSoyadi write FHastaSoyadi;
      property doctorId: Integer read FDoctorId write FDoctorId;
      constructor Create();
    end;

  TMuayene = class(TObject)
    public
      FMuayeneId: Integer;
      FHastaId: Integer;
      FImageCount: Integer;
      FMuayeneTarihi: TDateTime;
      property muayeneId: Integer read FMuayeneId write FMuayeneId;
      property hastaId: Integer read FHastaId write FHastaId;
      property imageCount: Integer read FImageCount write FImageCount;
      property muayeneTarihi: TDateTime read FMuayeneTarihi write FMuayeneTarihi;
      constructor Create();
    end;

  THastaHastalik = class(TObject)
    public
      FHastaId: Integer;
      FHastalikId: Integer;
      FMuayeneId: Integer;
      FRightLeft: Integer;
      FHastalikTime: TDateTime;
      FHastalikScore: Double;
      property hastaId: Integer read FHastaId write FHastaId;
      property hastalikId: Integer read FHastalikId write FHastalikId;
      property muayeneId: Integer read FMuayeneId write FMuayeneId;
      property rightLeft: Integer read FRightLeft write FRightLeft;
      property hastalikTime: TDateTime read FHastalikTime write FHastalikTime;
      property hastalikScore: Double read FHastalikScore write FHastalikScore;
      constructor Create();
    end;

implementation

uses BasicLogger;

{ TSendClientLogRequestDTO }

constructor TSendClientLogRequestDTO.Create;
begin

end;

{ TCreateAnalysisRequestDTO }

constructor TCreateAnalysisRequestDTO.Create;
begin

end;


function TCreateAnalysisRequestDTO.getHasDiabetesAsBoolean(value: Integer): Boolean;
begin
  result := value = 1;
end;

function TCreateAnalysisRequestDTO.getModifiedPatientBirthDate(originalPatientBirthDate: TDateTime): TDateTime;
const
  MODIFIED_PATIENT_BIRTH_DAY = 1;
  MODIFIED_PATIENT_BIRTH_MONTH = 1;
var
  patientBirthYear, tempVar: Word;
begin
  try
    DecodeDateTime(originalPatientBirthDate, patientBirthYear,
                    tempVar, tempVar, tempVar, tempVar, tempVar, tempVar);
    Result := EncodeDateTime(patientBirthYear, MODIFIED_PATIENT_BIRTH_MONTH, MODIFIED_PATIENT_BIRTH_DAY,
                              0, 0, 0, 0);
  except on E: Exception do
    ErrorLog('TCreateAnalysisRequestDTO.getModifiedPatientBirthDate: Error while creating a modified TDateTime object for patient birthdate. '
              + E.Message);
  end;
end;

{ TCreateAnalysisResponseDTO }

constructor TCreateAnalysisResponseDTO.Create;
begin

end;

{ TImageInformation }

constructor TImageInformation.Create;
begin

end;

destructor TImageInformation.Destroy;
begin

  for var item in FLayerDetections do item.Free;
  for var item in FAnomalyDetections do item.Free;
  for var item in FAnomalyLayerDetections do item.Free;
  for var item in FAnomalyAreas do item.Free;

  inherited;
end;

{ TDataResponse }

constructor TDataResponse.Create;
begin

end;

destructor TDataResponse.Destroy;
begin

  for var item in FImageInfos do item.Free;

  inherited;
end;

{ TAnalysisResponseObj }

constructor TAnalysisResponseObj.Create;
begin

end;

destructor TAnalysisResponseObj.Destroy;
begin
  Fdata.Free;
  inherited;
end;

{ TPoint }

constructor TPoint.Create;
begin

end;

{ TUploadImage }

constructor TUploadImage.Create;
begin

end;

{ TDetection }

constructor TDetection.Create;
begin

end;

destructor TDetection.Destroy;
begin

  for var item in FPoints do item.Free;

  inherited;
end;

{ TAnomalyLayerDetection }

constructor TAnomalyLayerDetection.Create;
begin

end;

destructor TAnomalyLayerDetection.Destroy;
begin

  for var item in FLayers do item.Free;

  inherited;
end;

{ TLayer }

constructor TLayer.Create;
begin

end;

{ TUploadWorkerData }

constructor TUploadWorkerData.Create;
begin

end;

function TUploadWorkerData.ToString: string;
begin
  try
    Result := 'FAnalysisGuid: ' + FAnalysisGuid +
              ' FJwtToken: ' + FJwtToken +
              ' FMuayeneID: ' + FMuayeneID.ToString +
              ' FImageID : ' + FImageID.ToString;
  except on E: Exception do
    ErrorLog('TUploadWorkerData.ToString: Error : ' + E.Message);
  end;
end;

{ THasta }

constructor THasta.Create;
begin

end;

{ TMuayene }

constructor TMuayene.Create;
begin

end;

{ THastaHastalik }

constructor THastaHastalik.Create;
begin

end;

{ TNotAnalysedImageDTO }

function TNotAnalysedImageDTO.toTCreateAnalysisRequestDTO: TCreateAnalysisRequestDTO;
var
  CreateAnalysisRequestDTO: TCreateAnalysisRequestDTO;
begin
  CreateAnalysisRequestDTO := TCreateAnalysisRequestDTO.Create();

  CreateAnalysisRequestDTO.ProtocolNo := Self.ProtocolNo;
  CreateAnalysisRequestDTO.PatientName := Self.PatientName;
  CreateAnalysisRequestDTO.PatientSurname := 	Self.PatientSurname;
  CreateAnalysisRequestDTO.Physician := Self.Physician;
  CreateAnalysisRequestDTO.HasDiabetes := Self.HasDiabetes;
  CreateAnalysisRequestDTO.PatientBirthdate := Self.PatientBirthdate;
  CreateAnalysisRequestDTO.Photographer := Self.Photographer;
  CreateAnalysisRequestDTO.CommonImagePrefix := Self.CommonImagePrefix;
  CreateAnalysisRequestDTO.CommonImageExtension := Self.CommonImageExtension;
  CreateAnalysisRequestDTO.ImageCount := Self.ImageCount;
  CreateAnalysisRequestDTO.EyePosition := Self.EyePosition;

  Result := CreateAnalysisRequestDTO;
end;

end.

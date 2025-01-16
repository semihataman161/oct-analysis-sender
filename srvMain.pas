unit srvMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.SvcMgr, AppEvnts, OCTSettingsManager, ApiWrapper, UploadManager,
  UploadDataModule, Vcl.ExtCtrls;

type
  TOCTAnalysisSender = class(TService)
    ApplicationEvents1: TApplicationEvents;
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    destructor Destroy; override;
  private
    { Private declarations }
    FOCTSettingsManager: TOCTSettingsManager;
    FApiWrapper: TApiWrapper;
    FUploadManager: TUploadManager;
  public
    { Public declarations }
    function GetServiceController: TServiceController; override;
  end;

var
  OCTAnalysisSender: TOCTAnalysisSender;

implementation

uses
  BasicLogger;

{$R *.dfm}


procedure TOCTAnalysisSender.ApplicationEvents1Exception(
  Sender: TObject; E: Exception);
begin
  if E is EAbort Then Exit;
  ErrorLog( E.Message );
end;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  OCTAnalysisSender.Controller(CtrlCode);
end;

destructor TOCTAnalysisSender.Destroy;
begin
  FOCTSettingsManager.Free;
  FApiWrapper.Free;
  FUploadManager.Free;
  inherited;
end;

function TOCTAnalysisSender.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TOCTAnalysisSender.ServiceStart(Sender: TService; var Started: Boolean);
begin
  Started := False;
  Try
    ErrorLog('Starting OCTAnalysisSenderSvc upon request.');
    FOCTSettingsManager := TOCTSettingsManager.Create;
    FOCTSettingsManager.LoadSettings;
    FApiWrapper := TApiWrapper.Create(FOCTSettingsManager);
    FUploadManager := TUploadManager.Create(FOCTSettingsManager, FApiWrapper);

    ErrorLog('TOCTAnalysisSender.ServiceStart Initiating startup sequence...');
    {$ifndef REMOTE_CLIENT}
      if Not pUploadDataModule.ConnectDatabaseMain() then
      begin
        ErrorLog('Error : ' + EC_105 + 'Recommended action : ' +  RA_105);
        FApiWrapper.sendClientLog(ERROR, EC_105 + ' ' + RA_105);
        Exit;
      end;
    {$endif}

    FUploadManager.Start;

    Started := True;
    ErrorLog('OCTAnalysisSenderSvc started successfully.');
  Except
    on E: Exception do begin
      ErrorLog('TOCTAnalysisSender.ServiceStart: Error: ' + E.Message);
      Exit;
    End;
  End;
end;

procedure TOCTAnalysisSender.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  Stopped := False;
  try
    ErrorLog('Stopping service upon request.');
    FUploadManager.Terminate;
    FUploadManager.WaitFor;

    FreeAndNil(FUploadManager);
    FreeAndNil(FOCTSettingsManager);
    FreeAndNil(FApiWrapper);

    Stopped := True;
    ErrorLog('Service stopped normally.');
  Except
    on E: Exception do begin
      ErrorLog('TOCTAnalysisSender.ServiceStop: Error: ' + E.Message);
      Exit;
    End;
  End;
end;

end.

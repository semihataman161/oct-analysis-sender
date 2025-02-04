program OCTAnalysisSenderSvc;
{$ifdef DEBUG}
  {$APPTYPE CONSOLE}
{$endif}
uses
  Vcl.SvcMgr,
  System.SysUtils, System.Classes,
  srvMain in 'srvMain.pas' {Service1: TService},
  BasicLogger in 'utils\BasicLogger.pas',
  TntLXCryptoUtils in 'utils\TntLXCryptoUtils.pas',
  RegistrationModel in 'utils\models\RegistrationModel.pas',
  EcuImageType in 'utils\EcuImageType.pas',
  RequestHelper in 'utils\RequestHelper.pas',
  FileUtil in 'utils\FileUtil.pas',
  UploadManager in 'UploadManager.pas',
  HtmlToPdfConverter in 'utils\HtmlToPdfConverter.pas',
  utilFile in 'utils\utilFile.pas',
  OCTSettingsManager in 'OCTSettingsManager.pas',
  ApiWrapper in 'ApiWrapper.pas',
  UploadWorker in 'UploadWorker.pas',
  DTO in 'DTO.pas',
  UploadDataModule in 'UploadDataModule.pas' {UploadDataModule: TDataModule},
  QueueStatus in 'QueueStatus.pas';

{$R *.RES}
begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //

  {$ifdef DEBUG}
    ReportMemoryLeaksOnShutdown := True;
    IsConsole:= False; //hack to show memory leaks
    var keepRunning := True;
    //to stop execution when enter pressed
    TThread.CreateAnonymousThread(
        procedure begin
          Readln;
          keepRunning := False;
        end
      ).Start;

    if not Application.DelayInitialize or Application.Installing then
      Application.Initialize;
    Application.CreateForm(TOCTAnalysisSender, OCTAnalysisSender);
    Application.CreateForm(TUploadDataModule, pUploadDataModule);
  { simulate application run }
    var Started := False;
    OCTAnalysisSender.ServiceStart(OCTAnalysisSender, Started);

    while keepRunning do begin
      Sleep(500);
    end;

    OCTAnalysisSender.ServiceStop(OCTAnalysisSender, Started);
    FreeAndNil(pUploadDataModule);
    FreeAndNil(OCTAnalysisSender);
  {$else}
    if not Application.DelayInitialize or Application.Installing then
      Application.Initialize;
    Application.CreateForm(TOCTAnalysisSender, OCTAnalysisSender);
    Application.CreateForm(TUploadDataModule, pUploadDataModule);
    Application.Run;
  {$endif}

end.

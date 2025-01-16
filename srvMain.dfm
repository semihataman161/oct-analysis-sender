object OCTAnalysisSender: TOCTAnalysisSender
  Dependencies = <
    item
      Name = 'mysql51'
      IsGroup = False
    end>
  DisplayName = 'OCTAnalysisSender'
  Interactive = True
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 316
  Width = 403
  PixelsPerInch = 120
  object ApplicationEvents1: TApplicationEvents
    OnException = ApplicationEvents1Exception
    Left = 100
    Top = 60
  end
end

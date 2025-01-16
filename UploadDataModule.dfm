object UploadDataModule: TUploadDataModule
  Height = 590
  Width = 750
  PixelsPerInch = 120
  object ZConnection1: TZConnection
    ControlsCodePage = cCP_UTF16
    AutoEncodeStrings = True
    ClientCodepage = 'utf8'
    Catalog = 'eye_checkup'
    Properties.Strings = (
      'controls_cp=CP_UTF16'
      'AutoEncodeStrings=ON'
      'MYSQL_SSL=true'
      'codepage=utf8')
    Connected = True
    HostName = 'localhost'
    Port = 3307
    Database = 'eye_checkup'
    User = 'root'
    Password = 'rootpass'
    Protocol = 'mysql-5'
    LibraryLocation = 'C:\App\libmySQL.dll'
    Left = 70
    Top = 50
  end
  object bufferBatch: TZSQLProcessor
    Params = <>
    Connection = ZConnection1
    Delimiter = ';'
    Left = 190
    Top = 50
  end
  object qryNotAnalysedHasta: TZQuery
    Connection = ZConnection1
    Filter = 'hasta_status = 0'
    Filtered = True
    SQL.Strings = (
      'SELECT *'
      'FROM b_hasta b '
      'WHERE b.hasta_ID = :hasta_ID;')
    Params = <
      item
        DataType = ftUnknown
        Name = 'hasta_ID'
        ParamType = ptUnknown
      end>
    DataSource = srcMuayene
    Left = 70
    Top = 230
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'hasta_ID'
        ParamType = ptUnknown
      end>
    object qryNotAnalysedHastahasta_numarasi: TWideStringField
      FieldName = 'hasta_numarasi'
      Size = 255
    end
    object qryNotAnalysedHastahasta_adi: TWideStringField
      FieldName = 'hasta_adi'
      Size = 50
    end
    object qryNotAnalysedHastahasta_soyadi: TWideStringField
      FieldName = 'hasta_soyadi'
      Size = 50
    end
    object qryNotAnalysedHastahasta_birthday: TDateField
      FieldName = 'hasta_birthday'
    end
    object qryNotAnalysedHastahas_diabetes: TSmallintField
      FieldName = 'has_diabetes'
    end
    object qryNotAnalysedHastahasta_ID: TLongWordField
      FieldName = 'hasta_ID'
      Required = True
    end
    object qryNotAnalysedHastahasta_status: TSmallintField
      FieldName = 'hasta_status'
      Required = True
    end
    object qryNotAnalysedHastapatient_ID_issuer: TWideStringField
      FieldName = 'patient_ID_issuer'
      Required = True
      Size = 50
    end
    object qryNotAnalysedHastadoctor_ID: TLongWordField
      FieldName = 'doctor_ID'
    end
    object qryNotAnalysedHastahasta_sex: TWideStringField
      FieldName = 'hasta_sex'
      Size = 10
    end
    object qryNotAnalysedHastahasta_telefonu: TWideStringField
      FieldName = 'hasta_telefonu'
      Size = 15
    end
    object qryNotAnalysedHastahasta_adres1: TWideStringField
      FieldName = 'hasta_adres1'
      Size = 100
    end
    object qryNotAnalysedHastahasta_not: TWideStringField
      FieldName = 'hasta_not'
      Size = 255
    end
    object qryNotAnalysedHastahasta_kayityeri: TIntegerField
      FieldName = 'hasta_kayityeri'
    end
    object qryNotAnalysedHastareferring_doctor_ID: TLongWordField
      FieldName = 'referring_doctor_ID'
    end
    object qryNotAnalysedHastagrp1: TLongWordField
      FieldName = 'grp1'
    end
    object qryNotAnalysedHastagrp2: TLongWordField
      FieldName = 'grp2'
    end
    object qryNotAnalysedHastagrp3: TWideStringField
      FieldName = 'grp3'
      Size = 255
    end
    object qryNotAnalysedHastagrp4: TWideStringField
      FieldName = 'grp4'
      Size = 255
    end
    object qryNotAnalysedHastahasta_deleted: TDateField
      FieldName = 'hasta_deleted'
    end
    object qryNotAnalysedHastapatient_middle_names: TWideStringField
      FieldName = 'patient_middle_names'
      Size = 100
    end
    object qryNotAnalysedHastapatient_prefixes: TWideStringField
      FieldName = 'patient_prefixes'
      Size = 50
    end
    object qryNotAnalysedHastapatient_suffixes: TWideStringField
      FieldName = 'patient_suffixes'
      Size = 50
    end
    object qryNotAnalysedHastaaccession_number: TWideStringField
      FieldName = 'accession_number'
      Size = 100
    end
    object qryNotAnalysedHastahasta_last_study_ID: TIntegerField
      FieldName = 'hasta_last_study_ID'
    end
    object qryNotAnalysedHastahasta_tarihi: TDateTimeField
      FieldName = 'hasta_tarihi'
    end
  end
  object srcHasta: TDataSource
    DataSet = qryNotAnalysedHasta
    Left = 190
    Top = 230
  end
  object srcMuayene: TDataSource
    Left = 190
    Top = 150
  end
  object srcPhysician: TDataSource
    DataSet = qryPhysician
    Left = 190
    Top = 380
  end
  object qryPhysician: TZQuery
    Connection = ZConnection1
    SortedFields = 'doctor_ID'
    SQL.Strings = (
      'SELECT *'
      'FROM b_doctors b '
      'WHERE b.doctor_ID = :doctor_ID')
    Params = <
      item
        DataType = ftUnknown
        Name = 'doctor_ID'
        ParamType = ptUnknown
      end>
    IndexFieldNames = 'doctor_ID Asc'
    Left = 70
    Top = 380
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'doctor_ID'
        ParamType = ptUnknown
      end>
    object qryPhysiciandoctor_ID: TIntegerField
      FieldName = 'doctor_ID'
      Required = True
    end
    object qryPhysicianuser_name: TWideStringField
      FieldName = 'user_name'
    end
    object qryPhysicianaccount_expires: TDateField
      FieldName = 'account_expires'
    end
    object qryPhysicianchange_pw: TWideStringField
      FieldName = 'change_pw'
      Size = 5
    end
    object qryPhysicianuser_pw: TWideStringField
      FieldName = 'user_pw'
    end
    object qryPhysicianreal_name: TWideStringField
      FieldName = 'real_name'
      Size = 50
    end
    object qryPhysicianreal_surname: TWideStringField
      FieldName = 'real_surname'
      Size = 50
    end
    object qryPhysicianuser_status: TShortintField
      FieldKind = fkCalculated
      FieldName = 'user_status'
      Calculated = True
    end
  end
  object qryPhotographer: TZQuery
    Connection = ZConnection1
    SQL.Strings = (
      'SELECT *'
      'FROM b_photographers b  '
      'WHERE photographer_ID = :photographer_ID;')
    Params = <
      item
        DataType = ftUnknown
        Name = 'photographer_ID'
        ParamType = ptUnknown
      end>
    DataSource = srcMuayene
    Left = 70
    Top = 450
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'photographer_ID'
        ParamType = ptUnknown
      end>
    object qryPhotographerphotographer_ID: TIntegerField
      FieldName = 'photographer_ID'
      Required = True
    end
    object qryPhotographerphotographer_name: TWideStringField
      FieldName = 'photographer_name'
      Size = 50
    end
  end
  object srcPhotographer: TDataSource
    DataSet = qryPhotographer
    Left = 190
    Top = 450
  end
  object qryNotAnalysedImage: TZQuery
    Connection = ZConnection1
    SQL.Strings = (
      'SELECT i.*, '
      #9'h.hasta_ID as hasta_ID, '
      #9'h.hasta_numarasi as hasta_numarasi, '
      #9'h.hasta_adi as hasta_adi, '
      #9'h.hasta_soyadi as hasta_soyadi,'
      #9'h.has_diabetes as has_diabetes,'
      #9'h.hasta_birthday as hasta_birthday,'
      #9'd.real_name as physician,'
      #9'p.photographer_name as photographer'
      'FROM b_image i '
      'JOIN b_muayene m ON m.muayene_ID = i.muayene_ID'
      'JOIN b_hasta h ON h.hasta_ID = m.hasta_ID'
      'LEFT JOIN b_doctors d ON d.doctor_ID = h.doctor_ID'
      
        'LEFT JOIN b_photographers p ON p.photographer_ID = m.photographe' +
        'r_ID'
      
        'LEFT JOIN b_queue q ON q.oct_image_id = i.image_ID AND q.muayene' +
        '_ID = m.muayene_ID'
      'WHERE i.image_right_left IN (1,2) AND i.image_type=5'
      'AND q.queue_id IS NULL')
    Params = <>
    DataSource = srcMuayene
    Left = 70
    Top = 310
    object qryNotAnalysedImageimage_ID: TLongWordField
      FieldName = 'image_ID'
      Required = True
    end
    object qryNotAnalysedImagemuayene_ID: TLongWordField
      FieldName = 'muayene_ID'
    end
    object qryNotAnalysedImageinstance_UID: TWideStringField
      FieldName = 'instance_UID'
      Size = 255
    end
    object qryNotAnalysedImageimage_right_left: TLongWordField
      FieldName = 'image_right_left'
    end
    object qryNotAnalysedImagemuayene_resim_no: TSmallintField
      FieldName = 'muayene_resim_no'
    end
    object qryNotAnalysedImageimage_name: TWideStringField
      FieldName = 'image_name'
      Size = 50
    end
    object qryNotAnalysedImageimage_path: TWideStringField
      FieldName = 'image_path'
      Size = 100
    end
    object qryNotAnalysedImageimage_note: TWideStringField
      FieldName = 'image_note'
      Size = 150
    end
    object qryNotAnalysedImageimage_time: TDateTimeField
      FieldName = 'image_time'
    end
    object qryNotAnalysedImageimage_type: TSmallintField
      FieldName = 'image_type'
      Required = True
    end
    object qryNotAnalysedImageselectimg: TSmallintField
      FieldName = 'selectimg'
    end
    object qryNotAnalysedImageANNOTATIONS: TWideMemoField
      FieldName = 'ANNOTATIONS'
      BlobType = ftWideMemo
    end
    object qryNotAnalysedImageimage_status: TSmallintField
      FieldName = 'image_status'
    end
    object qryNotAnalysedImagegrp1: TLongWordField
      FieldName = 'grp1'
    end
    object qryNotAnalysedImagegrp2: TWideStringField
      FieldName = 'grp2'
      Size = 45
    end
    object qryNotAnalysedImageimage_deleted: TDateField
      FieldName = 'image_deleted'
    end
    object qryNotAnalysedImagepredictions: TWideMemoField
      FieldName = 'predictions'
      BlobType = ftWideMemo
    end
    object qryNotAnalysedImagecentered_object: TWideMemoField
      FieldName = 'centered_object'
      BlobType = ftWideMemo
    end
    object qryNotAnalysedImagecapture_type: TSmallintField
      FieldName = 'capture_type'
    end
    object qryNotAnalysedImageframe_count: TIntegerField
      FieldName = 'frame_count'
    end
    object qryNotAnalysedImageprediction_size: TIntegerField
      FieldName = 'prediction_size'
    end
    object qryNotAnalysedImagehasta_numarasi: TWideStringField
      FieldName = 'hasta_numarasi'
      Size = 255
    end
    object qryNotAnalysedImagehasta_adi: TWideStringField
      FieldName = 'hasta_adi'
      Size = 50
    end
    object qryNotAnalysedImagehasta_soyadi: TWideStringField
      FieldName = 'hasta_soyadi'
      Size = 50
    end
    object qryNotAnalysedImagephysician: TWideStringField
      FieldName = 'physician'
      Size = 50
    end
    object qryNotAnalysedImagephotographer: TWideStringField
      FieldName = 'photographer'
      Size = 50
    end
    object qryNotAnalysedImagehasta_birthday: TDateField
      FieldName = 'hasta_birthday'
    end
    object qryNotAnalysedImagehas_diabetes: TSmallintField
      FieldName = 'has_diabetes'
    end
    object qryNotAnalysedImagehasta_ID: TLongWordField
      FieldName = 'hasta_ID'
      Required = True
    end
  end
  object srcImage: TDataSource
    DataSet = qryNotAnalysedHasta
    Left = 190
    Top = 310
  end
  object qryAnalysisQueue: TZQuery
    Connection = ZConnection1
    Filter = 'is_completed = 0'
    Filtered = True
    SQL.Strings = (
      'SELECT *'
      'FROM b_queue b  '
      'WHERE b.muayene_ID = :muayene_ID;')
    Params = <
      item
        DataType = ftUnknown
        Name = 'muayene_ID'
        ParamType = ptUnknown
      end>
    DataSource = srcMuayene
    Left = 350
    Top = 150
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'muayene_ID'
        ParamType = ptUnknown
      end>
    object qryAnalysisQueuequeue_id: TLongWordField
      FieldName = 'queue_id'
      Required = True
    end
    object qryAnalysisQueuediagnosis_guid: TWideStringField
      FieldName = 'diagnosis_guid'
      Required = True
      Size = 45
    end
    object qryAnalysisQueuequeue_date: TDateTimeField
      FieldName = 'queue_date'
    end
    object qryAnalysisQueuemuayene_id: TLongWordField
      FieldName = 'muayene_id'
      Required = True
    end
    object qryAnalysisQueueis_completed: TSmallintField
      FieldName = 'is_completed'
      Required = True
    end
    object qryAnalysisQueuequeue_complete_date: TDateTimeField
      FieldName = 'queue_complete_date'
    end
    object qryAnalysisQueuequeue_status: TWideStringField
      FieldName = 'queue_status'
      Size = 90
    end
    object qryAnalysisQueueoct_image_id: TLongWordField
      FieldName = 'oct_image_id'
    end
  end
  object srcAnalysisQueue: TDataSource
    DataSet = qryAnalysisQueue
    Left = 520
    Top = 150
  end
  object qryBuffer: TZQuery
    Connection = ZConnection1
    Params = <>
    Left = 430
    Top = 70
  end
  object qryHastalik: TZQuery
    Connection = ZConnection1
    SQL.Strings = (
      'SELECT * FROM hastalik'
      'ORDER BY DESCR;')
    Params = <>
    Left = 350
    Top = 230
    object qryHastalikID: TLargeintField
      FieldName = 'ID'
      Required = True
    end
    object qryHastalikDESCR: TWideStringField
      FieldName = 'DESCR'
      Size = 50
    end
    object qryHastalikHASTALIK: TWideStringField
      FieldName = 'HASTALIK'
      Size = 50
    end
  end
  object srcHastalik: TDataSource
    DataSet = qryHastalik
    Left = 520
    Top = 230
  end
  object qryMuayeneHastaHastalikR: TZQuery
    Connection = ZConnection1
    SQL.Strings = (
      'SELECT * FROM hasta_hastalik'
      'WHERE `right_left` = 2 AND muayene_ID = :muayene_ID'
      'ORDER BY `hastalik_time`')
    Params = <
      item
        DataType = ftUnknown
        Name = 'muayene_ID'
        ParamType = ptUnknown
      end>
    DataSource = srcMuayene
    Left = 350
    Top = 310
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'muayene_ID'
        ParamType = ptUnknown
      end>
    object qryMuayeneHastaHastalikRHASTA_ID: TLargeintField
      FieldName = 'HASTA_ID'
      Required = True
    end
    object qryMuayeneHastaHastalikRHASTALIK_ID: TLargeintField
      FieldName = 'HASTALIK_ID'
    end
    object qryMuayeneHastaHastalikRmuayene_ID: TLongWordField
      FieldName = 'muayene_ID'
    end
    object qryMuayeneHastaHastalikRright_left: TSmallintField
      FieldName = 'right_left'
    end
    object qryMuayeneHastaHastalikRhastalik_time: TDateTimeField
      FieldName = 'hastalik_time'
      Required = True
    end
    object qryMuayeneHastaHastalikRhastalik_notes: TWideStringField
      FieldName = 'hastalik_notes'
      Size = 255
    end
    object qryMuayeneHastaHastalikRhastalik_score: TFloatField
      FieldName = 'hastalik_score'
      Required = True
    end
    object qryMuayeneHastaHastalikRgrp2: TWideStringField
      FieldName = 'grp2'
      Size = 45
    end
  end
  object qryMuayeneHastaHastalikL: TZQuery
    Connection = ZConnection1
    SQL.Strings = (
      'SELECT * FROM hasta_hastalik'
      'WHERE `right_left` = 1 AND muayene_ID = :muayene_ID'
      'ORDER BY `hastalik_time`')
    Params = <
      item
        DataType = ftUnknown
        Name = 'muayene_ID'
        ParamType = ptUnknown
      end>
    DataSource = srcMuayene
    Left = 350
    Top = 390
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'muayene_ID'
        ParamType = ptUnknown
      end>
    object qryMuayeneHastaHastalikLHASTA_ID: TLargeintField
      FieldName = 'HASTA_ID'
      Required = True
    end
    object qryMuayeneHastaHastalikLHASTALIK_ID: TLargeintField
      FieldName = 'HASTALIK_ID'
    end
    object qryMuayeneHastaHastalikLmuayene_ID: TLongWordField
      FieldName = 'muayene_ID'
    end
    object qryMuayeneHastaHastalikLright_left: TSmallintField
      FieldName = 'right_left'
    end
    object qryMuayeneHastaHastalikLhastalik_time: TDateTimeField
      FieldName = 'hastalik_time'
      Required = True
    end
    object qryMuayeneHastaHastalikLhastalik_notes: TWideStringField
      FieldName = 'hastalik_notes'
      Size = 255
    end
    object qryMuayeneHastaHastalikLhastalik_score: TFloatField
      FieldName = 'hastalik_score'
      Required = True
    end
    object qryMuayeneHastaHastalikLgrp2: TWideStringField
      FieldName = 'grp2'
      Size = 45
    end
  end
  object srcMuayeneHastaHastalikL: TDataSource
    DataSet = qryMuayeneHastaHastalikL
    Left = 520
    Top = 390
  end
  object srcMuayeneHastaHastalikR: TDataSource
    DataSet = qryMuayeneHastaHastalikR
    Left = 520
    Top = 310
  end
  object tblImage: TZTable
    Connection = ZConnection1
    TableName = 'b_image'
    MasterSource = srcTblImage
    Left = 352
    Top = 480
    object tblImageimage_ID: TLongWordField
      FieldName = 'image_ID'
      Required = True
    end
    object tblImagemuayene_ID: TLongWordField
      FieldName = 'muayene_ID'
    end
    object tblImageinstance_UID: TWideStringField
      FieldName = 'instance_UID'
      Size = 255
    end
    object tblImageimage_right_left: TLongWordField
      FieldName = 'image_right_left'
    end
    object tblImagemuayene_resim_no: TSmallintField
      FieldName = 'muayene_resim_no'
    end
    object tblImageimage_name: TWideStringField
      FieldName = 'image_name'
      Size = 50
    end
    object tblImageimage_path: TWideStringField
      FieldName = 'image_path'
      Size = 100
    end
    object tblImageimage_note: TWideStringField
      FieldName = 'image_note'
      Size = 150
    end
    object tblImageimage_time: TDateTimeField
      FieldName = 'image_time'
    end
    object tblImageimage_type: TSmallintField
      FieldName = 'image_type'
    end
    object tblImageANNOTATIONS: TWideMemoField
      FieldName = 'ANNOTATIONS'
      BlobType = ftWideMemo
    end
  end
  object srcTblImage: TDataSource
    Left = 520
    Top = 480
  end
end

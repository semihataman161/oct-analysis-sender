unit OCTSettingsManager;
{$include defines.inc}
interface
uses System.SysUtils, System.IniFiles, RegistrationModel, TntLXCryptoUtils, System.Win.Registry,
     Winapi.Windows, IdHashSHA;
type
  TOCTSettingsManager = class
    FIniFilePath : String;
    FApiUrl: String;
    FAppVariant: String;
  public
    constructor Create;
    procedure LoadSettings;
    property ApiUrl: String read FApiUrl;
    const C_MYSQL_HOST_DEFAULT = 'localhost';
    const REG_IMAGING_KEY  = '\Software\Btt\NewVision';
    const REG_IMAGE_DIR_VAL = 'ImageDir';
    const REG_MYSQL_HOST = 'DatabaseHost';
    function readActivationInfo: TRegistrationInfo;
    function ReadActivationInfoFromIni: TRegistrationInfo;
    function getRegistrationSection: string;
    function getRegPath: String;
    function produceDigestSHA1: String;
  end;
implementation
uses BasicLogger;
const
  C_INI_FILE_NAME = 'imaging.ini';
  C_INI_SECTION_IMAGE_SETTINGS = 'ImageSettings';
  C_INI_SECTION_MOSAIC_MASKS   = 'MosaicMasks';
  C_INI_SECTION_APP_SETTINGS= 'AppSettings';
  C_INI_REG_STRING = 'RegString';
  C_INI_ACTIVATION_SIFRE = 'sifreleme_sifresi123456789';
  C_INI_OWNER_STRING  = 'RegOwner';
  C_INI_OWNER_COMPANY_STRING  = 'RegOwnerCompany';
  C_INI_OWNER_EMAIL_STRING  = 'RegOwnerEMail';
  C_INI_OWNER_PHONE_STRING  = 'RegOwnerPhone';
  C_INI_ACTIVATION_STRING = 'ActivationCode';
  C_INI_ACTIVATION_TYPE= 'ActivationType';
  C_INI_EXPIRY_DATE = 'ExpiryDate';
  C_INI_REMAINING_CREDIT = 'RemainingCredit';
  C_INI_TOTAL_CREDIT = 'TotalCredit';
  C_INI_LAST_CREDIT_QUERY_DATE = 'LastCreditQueryDate';
  C_INI_SECTION_REGISTRATION = 'Registration';
  LICENSE_TYPE_SAAS = '1';
  LICENSE_TYPE_PERMANENT = '0';
  RES_REG_PATH_BASE = '\Software\Windows';
  RES_REG_STRING    = 'RegString';
  RES_OWNER_STRING  = 'RegOwner';
  RES_ACTIVATION_STRING = 'ActivationCode';
  C_INI_API_BASE_URL = 'ApiBaseUrl';
  DefaultApiUrl = 'https://api.eyelabel.org';
{ TOCTSettingsManager }
constructor TOCTSettingsManager.Create;
begin
  FIniFilePath := GetPathTo(C_INI_FILE_NAME);
  FAppVariant := 'App';

  {$if DEFINED(FUNDUS_DICOM) or DEFINED(EXPORT_DICOM)}
    FAppVariant := FAppVariant + ' DICOM';
  {$endif}

  {$ifdef NV_PROFESSIONAL}
    FAppVariant := FAppVariant + ' Professional';
  {$endif}
end;
function TOCTSettingsManager.getRegistrationSection: String;
begin
  Result := C_INI_SECTION_REGISTRATION + '-' + FAppVariant;
end;

function TOCTSettingsManager.produceDigestSHA1: String;
const
  MESSAGE_DIGEST_SALT = 'LNKA`~JBI*ASD!3@bNI********d54n7234m2*-+1984awq3#irvgbuG$BUIRF^&V*BGIU87%56#$&*(^&^#$%#^&786568&7rv72qdfxiaudgbq7xvq873-t5+3iuq_os37=8hq2o';
var
  salted_msg: String;
  SHA1: TIdHashSHA1;
begin
  Result := '';
  SHA1 := TIdHashSHA1.Create;
  salted_msg := FAppVariant + ',btt_salt=' + MESSAGE_DIGEST_SALT;
  try
    Result := SHA1.HashStringAsHex(salted_msg);
  finally
    SHA1.Free;
  end;
end;
function TOCTSettingsManager.getRegPath: String;
begin
  Result := RES_REG_PATH_BASE + '\' + produceDigestSHA1;
end;
procedure TOCTSettingsManager.LoadSettings;
var
 myIniFile: TIniFile;
begin
  myIniFile := TIniFile.Create( FIniFilePath );
  if myIniFile.ValueExists(C_INI_SECTION_APP_SETTINGS,
                            C_INI_API_BASE_URL) then
  begin
      FApiUrl := myIniFile.ReadString( C_INI_SECTION_APP_SETTINGS,
                            C_INI_API_BASE_URL,
                            DefaultApiUrl );
  end
  else begin
  FApiUrl := DefaultApiUrl;
  myIniFile.WriteString( C_INI_SECTION_APP_SETTINGS,
                         C_INI_API_BASE_URL,
                         DefaultApiUrl );
  end;
  myIniFile.Free;
end;
function TOCTSettingsManager.ReadActivationInfoFromIni: TRegistrationInfo;
var
  myIniFile: TIniFile;
  regKeyfirstthreeletters, expiryCypherString, licenseCypherString,
  remainingCreditCypherString, totalCreditCypherString, lastCreditQueryDateCypherString: string;
  registrationInfo: TRegistrationInfo;
begin
  myIniFile := TIniFile.Create(FIniFilePath);
  try
    registrationInfo.RegKey :=
      myIniFile.ReadString(getRegistrationSection, C_INI_REG_STRING, '');
    regKeyfirstthreeletters := Copy(registrationInfo.RegKey, 1, 3);

    if (registrationInfo.RegKey <> '') and
       ((regKeyfirstthreeletters = 'nv-') or (regKeyfirstthreeletters = 'ec-')) then
      registrationInfo.RegKey := registrationInfo.RegKey
    else
      registrationInfo.RegKey := AES128_Decrypt(registrationInfo.RegKey, C_INI_ACTIVATION_SIFRE);

    registrationInfo.LicenseOwnerName :=
      myIniFile.ReadString(getRegistrationSection, C_INI_OWNER_STRING, '');
    registrationInfo.LicenseOwnerCompany :=
      myIniFile.ReadString(getRegistrationSection, C_INI_OWNER_COMPANY_STRING, '');
    registrationInfo.LicenseOwnerEMail :=
      myIniFile.ReadString(getRegistrationSection, C_INI_OWNER_EMAIL_STRING, '');
    registrationInfo.LicenseOwnerPhone :=
      myIniFile.ReadString(getRegistrationSection, C_INI_OWNER_PHONE_STRING, '');
    registrationInfo.ActivationCode :=
      myIniFile.ReadString(getRegistrationSection, C_INI_ACTIVATION_STRING, '');

    expiryCypherString := myIniFile.ReadString(getRegistrationSection, C_INI_EXPIRY_DATE, '');
    remainingCreditCypherString := myIniFile.ReadString(getRegistrationSection, C_INI_REMAINING_CREDIT, '');
    totalCreditCypherString := myIniFile.ReadString(getRegistrationSection, C_INI_TOTAL_CREDIT, '');
    lastCreditQueryDateCypherString := myIniFile.ReadString(getRegistrationSection, C_INI_LAST_CREDIT_QUERY_DATE, '');
    licenseCypherString := myIniFile.ReadString(getRegistrationSection, C_INI_ACTIVATION_TYPE, '');

    try
      if expiryCypherString <> '' then
        registrationInfo.ExpiryDateString := AES128_Decrypt(expiryCypherString, C_INI_ACTIVATION_SIFRE)
      else
        ErrorLog('Error: Settings manager: Expiry date cannot be read.');
    except
      on E: Exception do
        ErrorLog('Error: Settings manager: ExpiryDate Decrypt Failed.' + e.Message);
    end;

    try
      if remainingCreditCypherString <> '' then
      begin
        var value := AES128_Decrypt(remainingCreditCypherString, C_INI_ACTIVATION_SIFRE);
        if value = '' then
          registrationInfo.RemainingCredit := -1
        else
          registrationInfo.RemainingCredit := StrToInt(value);
      end
      else
        ErrorLog('Error: Settings manager: Remaining credit cannot be read.');
    except
      on E: Exception do
        ErrorLog('Error: Settings manager: RemainingCredit Decrypt Failed.' + e.Message);
    end;

    try
      if totalCreditCypherString <> '' then
      begin
        var value := AES128_Decrypt(totalCreditCypherString, C_INI_ACTIVATION_SIFRE);
        if value = '' then
          registrationInfo.TotalCredit := -1
        else
          registrationInfo.TotalCredit := StrToInt(value);
      end
      else
        ErrorLog('Error: Settings manager: Total credit cannot be read.');
    except
      on E: Exception do
        ErrorLog('Error: Settings manager: TotalCredit Decrypt Failed.' + e.Message);
    end;

    try
      if lastCreditQueryDateCypherString <> '' then
        registrationInfo.LastCreditQueryDateString := AES128_Decrypt(lastCreditQueryDateCypherString, C_INI_ACTIVATION_SIFRE)
      else
        ErrorLog('Error: Settings manager: Last credit query date cannot be read.');
    except
      on E: Exception do
        ErrorLog('Error: Settings manager: LastCreditQueryDate Decrypt Failed.' + e.Message);
    end;

    try
      if licenseCypherString <> '' then
        registrationInfo.ActivationType := AES128_Decrypt(licenseCypherString, C_INI_ACTIVATION_SIFRE)
      else
      begin
        registrationInfo.ActivationType := LICENSE_TYPE_PERMANENT;
        ErrorLog('Error: Settings manager: Activation type not found.');
      end;
    except
      on e: Exception do
      begin
        registrationInfo.ActivationType := LICENSE_TYPE_PERMANENT;
        ErrorLog('Error: Settings manager: ActivationType Decrypt Failed.' + e.Message);
      end;
    end;
  finally
    myIniFile.Free;
  end;

  // Return the registrationInfo variable explicitly
  Result := registrationInfo;
end;

function TOCTSettingsManager.readActivationInfo: TRegistrationInfo;
var
  Reg: TRegistry;
  FRegKeyfirstthreeletters: string;
  expiryCypherString, licenseCypherString: string;
  registrationInfo: TRegistrationInfo;
begin
  registrationInfo := ReadActivationInfoFromIni;

  if registrationInfo.ActivationCode = '' then
  begin
    try
      Reg := TRegistry.Create;
      try
        // Try reading in user space if no reg data found in Local Machine space
        Reg.RootKey := HKEY_CURRENT_USER;
        if Reg.OpenKey(getRegPath(), false) then
        begin
          if Reg.ValueExists(RES_REG_STRING) then
            registrationInfo.RegKey := Reg.ReadString(RES_REG_STRING);
          if Reg.ValueExists(RES_OWNER_STRING) then
            registrationInfo.LicenseOwnerName := Reg.ReadString(RES_OWNER_STRING);
          if Reg.ValueExists(RES_ACTIVATION_STRING) then
            registrationInfo.ActivationCode := Reg.ReadString(RES_ACTIVATION_STRING);
        end;

        Result := registrationInfo; // Return the result explicitly

      finally
        Reg.Free;
      end;
    except
      on E: Exception do
      begin
        ErrorLog('TOCTSettingsManager.readActivationInfo: Error validating license! ' + E.Message);
      end;
    end;
  end
  else
    Result := registrationInfo; // Return the registrationInfo if ActivationCode is not empty
end;

end.

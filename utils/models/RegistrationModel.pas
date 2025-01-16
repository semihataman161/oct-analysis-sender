unit RegistrationModel;

interface

type
  TRegistrationInfo = Record
    ExpiryDateString, ActivationCode, LicenseOwnerCompany, ActivationType
    , RegKey, LicenseOwnerName, LicenseOwnerEMail, LicenseOwnerPhone, LastCreditQueryDateString: String;
    RegVersion, RegType, RemainingCredit, TotalCredit: Integer;
  End;

implementation

end.


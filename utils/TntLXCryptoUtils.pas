unit TntLXCryptoUtils;

interface

function AES128_Encrypt(Value, Password: string): string;
function AES128_Decrypt(Value, Password: string): string;



implementation

uses
  SysUtils, Windows, IdCoderMIME, IdGlobal,IdCoder, IdCoder3to4;

//-------------------------------------------------------------------------------------------------------------------------
//    Base64 Encode/Decode
//-------------------------------------------------------------------------------------------------------------------------

function Base64_Encode(Value: TIdBytes): string;
var
  Encoder: TIdEncoderMIME;
begin
  Encoder := TIdEncoderMIME.Create(nil);
  try
    Result := Encoder.EncodeBytes(Value);
  finally
    Encoder.Free;
  end;
end;

function Base64_Decode(Value: string): TIdBytes;
var
  Decoder: TIdDecoderMIME;
begin
  Decoder := TIdDecoderMIME.Create(nil);
  try
    Result := Decoder.DecodeBytes(Value);
  finally
    Decoder.Free;
  end;
end;

//-------------------------------------------------------------------------------------------------------------------------
//    WinCrypt.h
//-------------------------------------------------------------------------------------------------------------------------

type
  HCRYPTPROV  = Cardinal;
  HCRYPTKEY   = Cardinal;
  ALG_ID      = Cardinal;
  HCRYPTHASH  = Cardinal;

const
  _lib_ADVAPI32    = 'ADVAPI32.dll';
  CALG_SHA_256     = 32780;
  CALG_AES_128     = 26126;
  CRYPT_NEWKEYSET  = $00000008;
  PROV_RSA_AES     = 24;
  KP_MODE          = 4;
  CRYPT_MODE_CBC   = 1;

function CryptAcquireContext(var Prov: HCRYPTPROV; Container: PChar; Provider: PChar; ProvType: LongWord; Flags: LongWord): LongBool; stdcall; external _lib_ADVAPI32 name 'CryptAcquireContextW';
function CryptDeriveKey(Prov: HCRYPTPROV; Algid: ALG_ID; BaseData: HCRYPTHASH; Flags: LongWord; var Key: HCRYPTKEY): LongBool; stdcall; external _lib_ADVAPI32 name 'CryptDeriveKey';
function CryptSetKeyParam(hKey: HCRYPTKEY; dwParam: LongInt; pbData: PBYTE; dwFlags: LongInt): LongBool stdcall; stdcall; external _lib_ADVAPI32 name 'CryptSetKeyParam';
function CryptEncrypt(Key: HCRYPTKEY; Hash: HCRYPTHASH; Final: LongBool; Flags: LongWord; pbData: PBYTE; var Len: LongInt; BufLen: LongInt): LongBool;stdcall;external _lib_ADVAPI32 name 'CryptEncrypt';
function CryptDecrypt(Key: HCRYPTKEY; Hash: HCRYPTHASH; Final: LongBool; Flags: LongWord; pbData: PBYTE; var Len: LongInt): LongBool; stdcall; external _lib_ADVAPI32 name 'CryptDecrypt';
function CryptCreateHash(Prov: HCRYPTPROV; Algid: ALG_ID; Key: HCRYPTKEY; Flags: LongWord; var Hash: HCRYPTHASH): LongBool; stdcall; external _lib_ADVAPI32 name 'CryptCreateHash';
function CryptHashData(Hash: HCRYPTHASH; Data: PChar; DataLen: LongWord; Flags: LongWord): LongBool; stdcall; external _lib_ADVAPI32 name 'CryptHashData';
function CryptReleaseContext(hProv: HCRYPTPROV; dwFlags: LongWord): LongBool; stdcall; external _lib_ADVAPI32 name 'CryptReleaseContext';
function CryptDestroyHash(hHash: HCRYPTHASH): LongBool; stdcall; external _lib_ADVAPI32 name 'CryptDestroyHash';
function CryptDestroyKey(hKey: HCRYPTKEY): LongBool; stdcall; external _lib_ADVAPI32 name 'CryptDestroyKey';

//-------------------------------------------------------------------------------------------------------------------------

{$WARN SYMBOL_PLATFORM OFF}

function __CryptAcquireContext(ProviderType: Integer): HCRYPTPROV;
begin
  if (not CryptAcquireContext(Result, nil, nil, ProviderType, 0)) then
  begin
    if HRESULT(GetLastError) = NTE_BAD_KEYSET then
      Win32Check(CryptAcquireContext(Result, nil, nil, ProviderType, CRYPT_NEWKEYSET))
    else
      RaiseLastOSError;
  end;
end;

function __AES128_DeriveKeyFromPassword(m_hProv: HCRYPTPROV; Password: string): HCRYPTKEY;
var
  hHash: HCRYPTHASH;
  Mode: DWORD;
begin
  Win32Check(CryptCreateHash(m_hProv, CALG_SHA_256, 0, 0, hHash));
  try
    Win32Check(CryptHashData(hHash, PChar(Password), Length(Password) * SizeOf(Char), 0));
    Win32Check(CryptDeriveKey(m_hProv, CALG_AES_128, hHash, 0, Result));
    // Wine uses a different default mode of CRYPT_MODE_EBC
    Mode := CRYPT_MODE_CBC;
    Win32Check(CryptSetKeyParam(Result, KP_MODE, Pointer(@Mode), 0));
  finally
    CryptDestroyHash(hHash);
  end;
end;

function AES128_Encrypt(Value, Password: string): string;
var
  hCProv: HCRYPTPROV;
  hKey: HCRYPTKEY;
  lul_datalen: Integer;
  lul_buflen: Integer;
  Buffer: TBytes;
  encodedBytes: TBytes;
  idBytes: TIdBytes;
  i: Integer;
begin
  Assert(Password <> '');
  if (Value = '') then
    Result := ''
  else begin
    hCProv := __CryptAcquireContext(PROV_RSA_AES);
    try
      hKey := __AES128_DeriveKeyFromPassword(hCProv, Password);
      try
        // allocate buffer space
        lul_datalen := Length(Value) * SizeOf(Char);
        SetLength(Buffer, lul_datalen*10);
        encodedBytes := TEncoding.Unicode.GetBytes(Value);
        for I := 0 to lul_datalen-1 do
        	Buffer[I] := encodedBytes[I];
                
        lul_buflen := Length(Buffer);
        // encrypt to buffer
        Win32Check(CryptEncrypt(hKey, 0, True, 0, @Buffer[0], lul_datalen, lul_buflen));
        //SetLength(Buffer, lul_datalen);
        SetLength(idBytes, lul_datalen);
        for i := 0 to lul_datalen-1 do
        begin
          idBytes[i] := Buffer[i];
        end;
        // base 64 result
        Result := Base64_Encode(idBytes);
      finally
        CryptDestroyKey(hKey);
      end;
    finally
      CryptReleaseContext(hCProv, 0);
    end;
  end;
end;

function AES128_Decrypt(Value, Password: string): string;
var
  hCProv: HCRYPTPROV;
  hKey: HCRYPTKEY;
  lul_datalen: Integer;
  Buffer: TBytes;
  idBytes : TIdBytes;
  i: Integer;
begin
  Assert(Password <> '');
  if Value = '' then
    Result := ''
  else begin
    hCProv := __CryptAcquireContext(PROV_RSA_AES);
    try
      hKey := __AES128_DeriveKeyFromPassword(hCProv, Password);
      try
        // decode base64
        idBytes := Base64_Decode(Value);
        // allocate buffer space
        lul_datalen := Length(idBytes);
        SetLength(Buffer, lul_datalen*100);
        for i := 0 to lul_datalen-1 do
          Buffer[i] := idBytes[i];
        // decrypt buffer to to string
        Win32Check(CryptDecrypt(hKey, 0, True, 0, @Buffer[0], lul_datalen));
        Result := TEncoding.Unicode.GetString(Buffer, 0, lul_datalen);
      finally
        CryptDestroyKey(hKey);
      end;
    finally
      CryptReleaseContext(hCProv, 0);
    end;
  end;
end;

end.

//{$define DEBUG_MESSAGES}

//{$define DEMO_BUILD}
{$ifdef DEMO_BUILD}
  {$define DEMO_MESSAGES}
{$endif}

{$define FUNDUS_DICOM}
{$define FUNDUS_PHOTO_USA}

{$ifdef FUNDUS_DICOM}
  {$define ONLINE_ACTIVATION}
{$endif}

{$ifdef FUNDUS_PHOTO_USA}
  {$define ONLINE_ACTIVATION}
  {$define LOGIN_REQUIRED}
  {$define USE_I2K_RETINA_MOSAIC}
  {$define EXPORT_DICOM} // Disable Server side functions, declare the EXPORT_DICOM_COMPILER in the  Project > Options > Delphi Compiler page.
//  {$define NV_PROFESSIONAL} // ModMed exporting image file list in the export file

  {$define VOLK_PICTOR}
//  {$define NV_TTI}
{$endif}

// Enable Image Transfer ONLY for Volk Pro, and all non-Volk versions
{$ifdef VOLK_PICTOR}
    {$define OPTIC_DISK_ALIGNMENT}
//    {$define DISABLE_SHELL_CHANGE_NOTIFIER}
{$endif}

{$ifdef DEMO_BUILD}
        {$define DEMO_MESSAGE}
{$endif}

{$undef LANGUAGE_TR}


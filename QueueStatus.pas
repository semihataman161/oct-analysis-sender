unit QueueStatus;

interface

type
  TQueueStatus = String;

const
  SUCCESSFULLY_COMPLETED_OCT_ANALYSIS: TQueueStatus = 'Analysis completed successfully';
  ERROR_WHILE_CREATING_OCT_ANALYSIS: TQueueStatus = 'Error while creating OCT analysis';
  ERROR_WHILE_STARTING_OCT_ANALYSIS: TQueueStatus = 'Error while starting OCT analysis';
  ERROR_WHILE_GETTING_OCT_ANALYSIS: TQueueStatus = 'Error while getting OCT analysis';
  TIMEOUT_WHILE_GETTING_OCT_ANALYSIS: TQueueStatus = 'Timeout while getting OCT analysis';
  ERROR_WHILE_GETTING_OCT_HTML_REPORT: TQueueStatus = 'Error while getting OCT html report';
  ERROR_WHILE_CONVERTING_OCT_HTML_REPORT_TO_PDF: TQueueStatus = 'Error while converting OCT html report to pdf';
  NO_IMAGE_UPLOADED_TO_S3: TQueueStatus = 'No image uploaded to S3';

implementation

end.

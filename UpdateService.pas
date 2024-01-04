unit UpdateService;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  IdHTTP, IdURI;

type
  TUpdateService = class(TService)
    Timer: TTimer;
    procedure ServiceCreate(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure ServiceAfterInstall(Sender: TService);
  strict private
    FAppPath: string;
    FUpdateURL: string;
    procedure CheckForUpdates;
    function GetFileVersion(const FileName: string): string;
    procedure LogException(const Msg: string);
  public
    constructor Create(AOwner: TComponent); override; // Add constructor
    procedure SetConfig(const AppPath, UpdateURL: string); // Add method to set config
    function GetServiceController: TServiceController; override;
  end;

var
  UpdateService: TUpdateService;

implementation

{$R *.dfm}

uses
  System.IOUtils;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  UpdateService.Controller(CtrlCode);
end;

function TUpdateService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TUpdateService.ServiceAfterInstall(Sender: TService);
begin
  // No need to set config here since it's now done externally
end;

procedure TUpdateService.ServiceCreate(Sender: TObject);
begin
  // Configuration should be set externally using SetConfig
end;

constructor TUpdateService.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAppPath := ''; // Initialize to empty, should be set using SetConfig
  FUpdateURL := ''; // Initialize to empty, should be set using SetConfig
end;

procedure TUpdateService.SetConfig(const AppPath, UpdateURL: string);
begin
  FAppPath := AppPath;
  FUpdateURL := UpdateURL;
end;

procedure TUpdateService.TimerTimer(Sender: TObject);
begin
  CheckForUpdates;
end;

procedure TUpdateService.CheckForUpdates;
var
  HTTPClient: TIdHTTP;
  VersionURL: string;
  NewVersion, CurrentVersion: string;
begin
  try
    VersionURL := TIdURI.URLEncode(FUpdateURL) + '?appversion=' + GetFileVersion(FAppPath + 'MyApp.exe');
    
    HTTPClient := TIdHTTP.Create(nil);
    try
      CurrentVersion := HTTPClient.Get(VersionURL);
    finally
      HTTPClient.Free;
    end;
    
    if CurrentVersion > GetCurrentVersion then
    begin
      ShellExecute(0, 'open', PChar('Updater.exe'), nil, nil, SW_SHOW);
    end;
  except
    on E: EIdException do
      LogException(E.Message);
    on E: Exception do
      LogException('Unexpected error: ' + E.Message);
  end;
end;

function TUpdateService.GetFileVersion(const FileName: string): string;
var
  Size, Handle: DWORD;
  Buffer: TBytes;
  FixedFileInfo: PVSFixedFileInfo;
  FileInfoSize: UINT;
begin
  Size := GetFileVersionInfoSize(PChar(FileName), Handle);
  if Size = 0 then
    RaiseLastOSError;

  SetLength(Buffer, Size);
  GetFileVersionInfo(PChar(FileName), Handle, Size, Buffer);

  if not VerQueryValue(Buffer, '\', Pointer(FixedFileInfo), FileInfoSize) then
    RaiseLastOSError;

  Result := Format('%d.%d.%d.%d',
    [LongRec(FixedFileInfo.dwFileVersionMS).Hi,
    LongRec(FixedFileInfo.dwFileVersionMS).Lo,
    LongRec(FixedFileInfo.dwFileVersionLS).Hi,
    LongRec(FixedFileInfo.dwFileVersionLS).Lo]);
end;

procedure TUpdateService.LogException(const Msg: string);
begin
  // Implement your logging mechanism here
end;

end.

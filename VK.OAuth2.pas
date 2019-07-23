unit VK.OAuth2;

interface

uses
  Windows, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  SHDocVw;

type
  TOAuth2WebFormRedirectEvent = procedure(const AURL: string; var DoCloseWebView: boolean) of object;

  TOAuth2WebFormTitleChangedEvent = procedure(const ATitle: string; var DoCloseWebView: boolean) of object;

  TFormOAuth2 = class(TForm)
    Browser: TWebBrowser;
    EditAddr: TEdit;
    Shape1: TShape;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure BrowserTitleChange(ASender: TObject; const Text: WideString);
    procedure FormCreate(Sender: TObject);
    procedure BrowserNavigateComplete2(ASender: TObject; const pDisp: IDispatch; const URL: OleVariant);
    procedure BrowserBeforeNavigate2(ASender: TObject; const pDisp: IDispatch; const URL, Flags, TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
    procedure EditAddrChange(Sender: TObject);
  private
    FOnBeforeRedirect: TOAuth2WebFormRedirectEvent;
    FOnAfterRedirect: TOAuth2WebFormRedirectEvent;
    FOnBrowserTitleChanged: TOAuth2WebFormTitleChangedEvent;
    FLastTitle: string;
    FLastURL: string;
    FNeedShow: Boolean;
  public
    procedure DeleteCache;
    procedure ShowWithURL(const AURL: string); overload;
    procedure ShowWithURL(Parent: TWinControl; const AURL: string); overload;
    property LastTitle: string read FLastTitle;
    property LastURL: string read FLastURL;
    property OnAfterRedirect: TOAuth2WebFormRedirectEvent read FOnAfterRedirect write FOnAfterRedirect;
    property OnBeforeRedirect: TOAuth2WebFormRedirectEvent read FOnBeforeRedirect write FOnBeforeRedirect;
    property OnTitleChanged: TOAuth2WebFormTitleChangedEvent read FOnBrowserTitleChanged write FOnBrowserTitleChanged;
  end;

var
  FormOAuth2: TFormOAuth2;

implementation

uses
  WinInet;

{$R *.dfm}

procedure TFormOAuth2.DeleteCache;
var
  lpEntryInfo: PInternetCacheEntryInfo;
  hCacheDir: LongWord;
  dwEntrySize: LongWord;
begin
  dwEntrySize := 0;
  FindFirstUrlCacheEntry(nil, TInternetCacheEntryInfo(nil^), dwEntrySize);
  GetMem(lpEntryInfo, dwEntrySize);
  if dwEntrySize > 0 then
    lpEntryInfo^.dwStructSize := dwEntrySize;
  hCacheDir := FindFirstUrlCacheEntry(nil, lpEntryInfo^, dwEntrySize);
  if hCacheDir <> 0 then
  begin
    repeat
      DeleteUrlCacheEntry(lpEntryInfo^.lpszSourceUrlName);
      FreeMem(lpEntryInfo, dwEntrySize);
      dwEntrySize := 0;
      FindNextUrlCacheEntry(hCacheDir, TInternetCacheEntryInfo(nil^), dwEntrySize);
      GetMem(lpEntryInfo, dwEntrySize);
      if dwEntrySize > 0 then
        lpEntryInfo^.dwStructSize := dwEntrySize;
    until not FindNextUrlCacheEntry(hCacheDir, lpEntryInfo^, dwEntrySize);
  end;
  FreeMem(lpEntryInfo, dwEntrySize);
  FindCloseUrlCache(hCacheDir);
end;

procedure TFormOAuth2.EditAddrChange(Sender: TObject);
begin
  if Copy(EditAddr.Text, 1, 6) = ' https' then
    EditAddr.Color := $00D8FFCC
  else
    EditAddr.Color := $0096AFFF;
end;

procedure TFormOAuth2.BrowserBeforeNavigate2(ASender: TObject; const pDisp: IDispatch; const URL, Flags, TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
var
  LDoCloseForm: boolean;
begin
  if Assigned(FOnBeforeRedirect) then
  begin
    LDoCloseForm := False;

    FOnBeforeRedirect(URL, LDoCloseForm);

    if LDoCloseForm then
    begin
      Cancel := True;
      Close;
    end;
  end;
end;

procedure TFormOAuth2.BrowserNavigateComplete2(ASender: TObject; const pDisp: IDispatch; const URL: OleVariant);
var
  LDoCloseForm: Boolean;
begin
  FLastURL := VarToStrDef(URL, '');
  EditAddr.Text := ' ' + FLastURL;
  Repaint;
  if Assigned(FOnAfterRedirect) then
  begin
    LDoCloseForm := False;

    FOnAfterRedirect(FLastURL, LDoCloseForm);

    if LDoCloseForm then
    begin
      FNeedShow := False;
      if Showing then
        Close;
    end;
  end;
end;

procedure TFormOAuth2.BrowserTitleChange(ASender: TObject; const Text: WideString);
var
  LCloseForm: boolean;
begin
  if (Text <> FLastTitle) then
  begin
    FLastTitle := Text;

    if Assigned(FOnBrowserTitleChanged) then
    begin
      LCloseForm := FALSE;
      FOnBrowserTitleChanged(FLastTitle, LCloseForm);

      if LCloseForm then
      begin
        FNeedShow := False;
        if Showing then
          Close;
      end;
    end;
  end;
end;

procedure TFormOAuth2.FormCreate(Sender: TObject);
begin
  FOnAfterRedirect := nil;
  FOnBeforeRedirect := nil;
  FOnBrowserTitleChanged := nil;

  FLastTitle := '';
  FLastURL := '';
end;

procedure TFormOAuth2.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #27) then
  begin
    Close;
  end;
end;

procedure TFormOAuth2.ShowWithURL(Parent: TWinControl; const AURL: string);
var
  TS: Cardinal;
begin
  SetParent(Parent);
  Align := alClient;
  BorderStyle := bsNone;

  FNeedShow := True;
  Browser.Navigate(AURL);
  TS := GetTickCount;
  while TS + 3000 > GetTickCount do
    Application.ProcessMessages;
  if FNeedShow then
    Show;
end;

procedure TFormOAuth2.ShowWithURL(const AURL: string);
var
  TS: Cardinal;
begin
  SetParent(nil);
  Align := alNone;
  BorderStyle := bsSizeable;
  FNeedShow := True;
  Browser.Navigate(AURL);
  TS := GetTickCount;
  while TS + 3000 > GetTickCount do
    Application.ProcessMessages;
  if FNeedShow then
    ShowModal;
end;

end.

{ *******************************************************************************
  *                                                                              *
  *  TksListView - Cached ListView Component                                     *
  *                                                                              *
  *  https://github.com/gmurt/KernowSoftwareFMX                                  *
  *                                                                              *
  *  Copyright 2015 Graham Murt                                                  *
  *                                                                              *
  *  email: graham@kernow-software.co.uk                                         *
  *                                                                              *
  *  Licensed under the Apache License, Version 2.0 (the "License");             *
  *  you may not use this file except in compliance with the License.            *
  *  You may obtain a copy of the License at                                     *
  *                                                                              *
  *    http://www.apache.org/licenses/LICENSE-2.0                                *
  *                                                                              *
  *  Unless required by applicable law or agreed to in writing, software         *
  *  distributed under the License is distributed on an "AS IS" BASIS,           *
  *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    *
  *  See the License for the specific language governing permissions and         *
  *  limitations under the License.                                              *
  *                                                                              *
  ******************************************************************************* }

unit ksListView;

interface

uses
  Classes, FMX.Types, FMX.Controls, FMX.ListView, Types, FMX.TextLayout,
  FMX.ListView.Types, FMX.Graphics, Generics.Collections, System.UITypes,
  FMX.ImgList, System.UIConsts, FMX.StdCtrls, FMX.Styles.Objects;

const
  C_LONG_TAP_DURATION = 5;  // 500 ms

type

  TksListView = class;
  TKsListItemRow = class;
  TksListItemRowObj = class;
  TksListItemRowSwitch = class;

  TksListViewRowClickEvent = procedure(Sender: TObject; x, y: single; AItem: TListViewItem; AId: string; ARowObj: TksListItemRowObj) of object;
  TksListViewClickSwitchEvent = procedure(Sender: TObject; AItem: TListViewItem; ASwitch: TksListItemRowSwitch; ARowID: string) of object;
  TksListViewFinishScrollingEvent = procedure(Sender: TObject; ATopIndex, AVisibleItems: integer) of object;


  // ------------------------------------------------------------------------------

  TksVisibleItems = record
    Count: integer;
    IndexStart: integer;
    IndexEnd: integer;
  end;

  TksListItemRowObj = class
  private
    FId: string;
    FRect: TRectF;
    FPlaceOffset: TPointF;
    FRow: TKsListItemRow;
    FAlign: TListItemAlign;
    FVertAlignment: TListItemAlign;
    FTagBoolean: Boolean;
    procedure SetRect(const Value: TRectF);
    procedure SetID(const Value: string);
    procedure Changed;
    procedure SetAlign(const Value: TListItemAlign);
    procedure CalculateRect(ARowBmp: TBitmap);
    procedure SetVertAlign(const Value: TListItemAlign);
  protected
    procedure DoChanged(Sender: TObject);
  public
    constructor Create(ARow: TKsListItemRow); virtual;
    function Render(ACanvas: TCanvas): Boolean; virtual;
    procedure Click(x, y: single); virtual;
    property Rect: TRectF read FRect write SetRect;
    property ID: string read FId write SetID;
    property Align: TListItemAlign read FAlign write SetAlign default TListItemAlign.Leading;
    property VertAlign: TListItemAlign read FVertAlignment write SetVertAlign default TListItemAlign.Center;
    property PlaceOffset: TPointF read FPlaceOffset write FPlaceOffset;
    property TagBoolean: Boolean read FTagBoolean write FTagBoolean;
  end;


  // ------------------------------------------------------------------------------

  TksListItemRowText = class(TksListItemRowObj)
  private
    FFont: TFont;
    FAlignment: TTextAlign;
    FTextLayout: TTextLayout;
    FTextColor: TAlphaColor;
    FText: string;
    FWordWrap: Boolean;
    procedure SetFont(const Value: TFont);
    procedure SetAlignment(const Value: TTextAlign);
    procedure SetTextColor(const Value: TAlphaColor);
    procedure SetText(const Value: string);
    procedure SetWordWrap(const Value: Boolean);
  public
    constructor Create(ARow: TKsListItemRow); override;
    destructor Destroy; override;
    function Render(ACanvas: TCanvas): Boolean; override;
    property Font: TFont read FFont write SetFont;
    property TextAlignment: TTextAlign read FAlignment write SetAlignment;
    property TextColor: TAlphaColor read FTextColor write SetTextColor;
    property Text: string read FText write SetText;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default False;
  end;

  // ------------------------------------------------------------------------------

  TksListItemRowImage = class(TksListItemRowObj)
  private
    FBitmap: TBitmap;
    procedure SetBitmap(const Value: TBitmap);
  public
    constructor Create(ARow: TKsListItemRow); override;
    destructor Destroy; override;
    function Render(ACanvas: TCanvas): Boolean; override;
    property Bitmap: TBitmap read FBitmap write SetBitmap;
  end;

  TKsListItemRowAccessory = class(TksListItemRowObj)
  private
    FResources: TListItemStyleResources;
    FAccessoryType: TAccessoryType;
    FImage: TStyleObject;
    procedure SetAccessoryType(const Value: TAccessoryType);
  public
    constructor Create(ARow: TKsListItemRow); override;
    function Render(ACanvas: TCanvas): Boolean; override;
    property AccessoryType: TAccessoryType read FAccessoryType write SetAccessoryType;
  end;

  TksListItemRowSwitch = class(TksListItemRowObj)
  private
    FIsChecked: Boolean;
    procedure SetIsChecked(const Value: Boolean);
  public
    function Render(ACanvas: TCanvas): Boolean; override;
    procedure Toggle;
    property IsChecked: Boolean read FIsChecked write SetIsChecked;

  end;

  TksListItemRowSegmentButtons = class(TksListItemRowObj)
  private
    FCaptions: TStrings;
    FItemIndex: integer;
    procedure SetItemIndex(const Value: integer);
  public
    constructor Create(ARow: TKsListItemRow); override;
    destructor Destroy; override;
    procedure Click(x, y: single); override;
    function Render(ACanvas: TCanvas): Boolean; override;
    property ItemIndex: integer read FItemIndex write SetItemIndex;
  end;


  // ------------------------------------------------------------------------------

  TKsListItemRow = class(TListItemImage)
  private
    FCached: Boolean;
    FFont: TFont;
    FTextColor: TAlphaColor;
    FIndicatorColor: TAlphaColor;
    FList: TObjectList<TksListItemRowObj>;
    FId: string;
    FAccessory: TKsListItemRowAccessory;

    FShowAccessory: Boolean;
    function TextHeight(AText: string): single;
    function TextWidth(AText: string): single;
    function RowHeight(const AScale: Boolean = True): single;
    function RowWidth(const AScale: Boolean = True): single;
    function GetListView: TCustomListView;
    function GetRowObject(AIndex: integer): TksListItemRowObj;
    function GetRowObjectCount: integer;
    procedure SetAccessory(const Value: TAccessoryType);
    procedure SetShowAccessory(const Value: Boolean);
    function GetAccessory: TAccessoryType;
    property ListView: TCustomListView read GetListView;
    procedure DoOnListChanged(Sender: TObject; const Item: TksListItemRowObj;
      Action: TCollectionNotification);
    function ScreenWidth: single;
  public
    constructor Create(const AOwner: TListItem);
    destructor Destroy; override;

    procedure CacheRow;
    // bitmap functions...
    function DrawBitmap(ABmp: TBitmap; x, AWidth, AHeight: single): TksListItemRowImage overload;
    function DrawBitmap(ABmpIndex: integer; x, AWidth, AHeight: single): TksListItemRowImage overload;
    function DrawBitmap(ABmp: TBitmap; x, y, AWidth, AHeight: single): TksListItemRowImage overload;
    function DrawBitmapRight(ABmp: TBitmap; AWidth, AHeight, ARightPadding: single): TksListItemRowImage;
    // switch
    function AddSwitch(x: single; AIsChecked: Boolean; const AAlign: TListItemAlign = TListItemAlign.Leading): TksListItemRowSwitch;
    function AddSwitchRight(AMargin: integer; AIsChecked: Boolean): TksListItemRowSwitch;

    // segment buttons...
    function AddSegmentButtons(AWidth, AXOffset: integer): TksListItemRowSegmentButtons;

    // text functions...
    function TextOut(AText: string; x: single; const AVertAlign: TTextAlign = TTextAlign.Center; const AWordWrap: Boolean = False): TksListItemRowText; overload;
    function TextOut(AText: string; x, AWidth: single; const AVertAlign: TTextAlign = TTextAlign.Center; const AWordWrap: Boolean = False): TksListItemRowText; overload;
    function TextOut(AText: string; x, y, AWidth: single; const AVertAlign: TTextAlign = TTextAlign.Center; const AWordWrap: Boolean = False): TksListItemRowText; overload;
    // right aligned text functions...

    function TextOutRight(AText: string; y, AWidth: single; AXOffset: single; const AVertAlign: TTextAlign = TTextAlign.Center): TksListItemRowText; overload;

    // font functions...
    procedure SetFontProperties(AName: string; ASize: integer; AColor: TAlphaColor; AStyle: TFontStyles);

    // properties...
    property Font: TFont read FFont;
    property TextColor: TAlphaColor read FTextColor write FTextColor;
    property RowObject[AIndex: integer]: TksListItemRowObj read GetRowObject;
    property RowObjectCount: integer read GetRowObjectCount;
    property ID: string read FId write FId;
    property Cached: Boolean read FCached write FCached;
    property IndicatorColor: TAlphaColor read FIndicatorColor write FIndicatorColor;
    property Accessory: TAccessoryType read GetAccessory write SetAccessory;
    property ShowAccessory: Boolean read FShowAccessory write SetShowAccessory default True;
  end;


  // ------------------------------------------------------------------------------

  TksListViewAppearence = class(TPersistent)
  private
    FListView: TksListView;
    FBackground: TAlphaColor;
    FItemBackground: TAlphaColor;
    FAlternatingItemBackground: TAlphaColor;
    procedure SetBackground(const Value: TAlphaColor);
    procedure SetItemBackground(const Value: TAlphaColor);
    procedure SetAlternatingItemBackground(const Value: TAlphaColor);
  public
    constructor Create(AListView: TksListView);
  published
    property Background: TAlphaColor read FBackground write SetBackground
      default claWhite;
    property ItemBackground: TAlphaColor read FItemBackground
      write SetItemBackground default claWhite;
    property AlternatingItemBackground: TAlphaColor
      read FAlternatingItemBackground write SetAlternatingItemBackground
      default claGainsboro;
  end;

  // ------------------------------------------------------------------------------

  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidiOSDevice)]
  TksListView = class(TCustomListView)
  private
    FScreenScale: single;
    FDefaultRowHeight: integer;
    FAppearence: TksListViewAppearence;
    FOnItemClickEx: TksListViewRowClickEvent;
    FOnItemRightClickEx: TksListViewRowClickEvent;
    FMouseDownPos: TPointF;
    FCurrentMousepos: TPointF;
    FItemHeight: integer;
    FClickTimer: TTimer;
    FLastWidth: integer;
    FMouseDownDuration: integer;
    FOnLongClick: TksListViewRowClickEvent;
    FClickedRowObj: TksListItemRowObj;
    FClickedItem: TListViewItem;
    FSelectOnRightClick: Boolean;
    FSwitchBmp: array[0..1] of TBitmap;
    FOnSwitchClicked: TksListViewClickSwitchEvent;
    FCacheTimer: TTimer;
    FScrollTimer: TTimer;
    FLastScrollPos: integer;
    FScrolling: Boolean;
    FOnFinishScrolling: TksListViewFinishScrollingEvent;
    procedure SetItemHeight(const Value: integer);
    procedure DoClickTimer(Sender: TObject);
    function GetCachedRow(index: integer): TKsListItemRow;
    procedure Invalidate;
    procedure OnCacheTimer(Sender: TObject);
    procedure StoreSwitchImages;
    procedure DoScrollTimer(Sender: TObject);
    { Private declarations }
  protected
    function GetSwitchImage(AIsChecked: Boolean): TBitmap;
    procedure SetColorStyle(AName: string; AColor: TAlphaColor);
    procedure Resize; override;
    procedure ApplyStyle; override;
    procedure DoItemClick(const AItem: TListViewItem); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; x, y: single); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; x, y: single); override;
    { Protected declarations }
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;


    procedure RedrawAllRows;
    function AddRow(const ASearchIndex: string = ''; const APurpose: TListItemPurpose = TListItemPurpose.None; const AId: string = ''): TKsListItemRow;
    function AddHeader(AText: string): TKsListItemRow;
    function ItemsInView: TksVisibleItems;
    procedure EndUpdate; override;
    property CachedRow[index: integer]: TKsListItemRow read GetCachedRow;


    { Public declarations }
  published
    property Appearence: TksListViewAppearence read FAppearence
      write FAppearence;
    property ItemHeight: integer read FItemHeight write SetItemHeight
      default 44;
    property OnEditModeChange;
    property OnEditModeChanging;
    property EditMode;

    property Transparent default False;
    property AllowSelection;
    property AlternatingColors;
    property ItemIndex;
    property Images;
    property ScrollViewPos;
    property ItemSpaces;
    property SideSpace;

    property OnItemClickEx: TksListViewRowClickEvent read FOnItemClickEx write FOnItemClickEx;
    property OnItemClickRightEx: TksListViewRowClickEvent read FOnItemRightClickEx write FOnItemRightClickEx;

    property Align;
    property Anchors;
    property CanFocus default True;
    property CanParentFocus;
    property ClipChildren default True;
    property ClipParent default False;
    property Cursor default crDefault;
    property DisableFocusEffect default True;
    property DragMode default TDragMode.dmManual;
    property EnableDragHighlight default True;
    property Enabled default True;
    property Locked default False;
    property Height;
    property HitTest default True;
    property Margins;
    property Opacity;
    property Padding;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property SelectOnRightClick: Boolean read FSelectOnRightClick write FSelectOnRightClick default False;
    property Size;
    property TabOrder;
    property TabStop;
    property Visible default True;
    property Width;

    { events }
    property OnApplyStyleLookup;
    { Drag and Drop events }
    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnDragDrop;
    property OnDragEnd;
    { Keyboard events }
    property OnKeyDown;
    property OnKeyUp;
    { Mouse events }
    property OnCanFocus;

    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseEnter;
    property OnMouseLeave;

    property OnPainting;
    property OnPaint;
    property OnResize;

    property HelpContext;
    property HelpKeyword;
    property HelpType;

    property StyleLookup;
    property TouchTargetExpansion;

    property OnDblClick;

    { ListView selection events }
    property CanSwipeDelete;

    property OnChange;
    property OnChangeRepainted;
    property OnItemsChange;
    property OnScrollViewChange;
    property OnItemClick;

    property OnButtonClick;
    property OnButtonChange;

    property OnDeletingItem;
    property OnDeleteItem;
    property OnDeleteChangeVisible;
    property OnSearchChange;
    property OnFilter;
    property OnPullRefresh;
    property DeleteButtonText;

    property AutoTapScroll;
    property AutoTapTreshold;
    property ShowSelection;
    property DisableMouseWheel;

    property SearchVisible;
    property SearchAlwaysOnTop;
    property SelectionCrossfade;
    property PullToRefresh;
    property PullRefreshWait;
    property OnLongClick: TksListViewRowClickEvent read FOnLongClick write FOnLongClick;
    property OnSwitchClick: TksListViewClickSwitchEvent read FOnSwitchClicked write FOnSwitchClicked;
    property OnScrollFinish: TksListViewFinishScrollingEvent read FOnFinishScrolling write FOnFinishScrolling;
  end;

procedure Register;

implementation

uses SysUtils, FMX.Platform, FMX.Forms, FMX.SearchBox;

const
{$IFDEF IOS}
  DefaultScrollBarWidth = 7;
{$ELSE}
{$IFDEF MACOS}
  DefaultScrollBarWidth = 7;
{$ENDIF}
{$ENDIF}

{$IFDEF MSWINDOWS}
  DefaultScrollBarWidth = 16;
{$ENDIF}

{$IFDEF ANDROID}
  DefaultScrollBarWidth = 7;
{$ENDIF}

procedure Register;
begin
  RegisterComponents('kernow Software FMX', [TksListView]);
end;

// ------------------------------------------------------------------------------

function GetScreenScale: single;
var
  Service: IFMXScreenService;
begin
  Service := IFMXScreenService(TPlatformServices.Current.GetPlatformService
    (IFMXScreenService));
  Result := Service.GetScreenScale;
{$IFDEF IOS}
  if Result = 1 then
    Result := 1.5;
{$ENDIF}
end;

// ------------------------------------------------------------------------------

{ TksListItemRowObj }

procedure TksListItemRowObj.CalculateRect(ARowBmp: TBitmap);
var
  w,h: single;
  ABmpWidth: single;
begin
  w := FRect.Width;
  h := FRect.Height;

  ABmpWidth := ARowBmp.Width / GetScreenScale;

  FRect := RectF(0, 0, w, h);
  if FAlign = TListItemAlign.Leading then
    OffsetRect(FRect, FPlaceOffset.X, 0);

  if FAlign = TListItemAlign.Trailing then
    OffsetRect(FRect, ABmpWidth - (FRect.Width+ DefaultScrollBarWidth + FPlaceOffset.X {+ FRow.ListView.ItemSpaces.Right}), 0);

  case VertAlign of
    TListItemAlign.Center: OffsetRect(FRect, 0, (FRow.Owner.Height - FRect.Height) / 2);
    TListItemAlign.Trailing: OffsetRect(FRect, 0, (FRow.Owner.Height - FRect.Height));
  end;

  OffsetRect(FRect, 0, FPlaceOffset.Y);
end;

procedure TksListItemRowObj.Changed;
begin
  FRow.Cached := False;
  //FRow.CacheRow;
  //FRow.ListView.Repaint;
end;

procedure TksListItemRowObj.Click(x, y: single);
begin
  //
end;

constructor TksListItemRowObj.Create(ARow: TKsListItemRow);
begin
  inherited Create;
  FRow := ARow;
  FAlign := TListItemAlign.Leading;
  FPlaceOffset := PointF(0,0);
  FTagBoolean := False;
end;

procedure TksListItemRowObj.DoChanged(Sender: TObject);
begin
  Changed;
end;

function TksListItemRowObj.Render(ACanvas: TCanvas): Boolean;
begin
  Result := True;

end;

procedure TksListItemRowObj.SetAlign(const Value: TListItemAlign);
begin
  FAlign := Value;
  Changed;
end;

procedure TksListItemRowObj.SetID(const Value: string);
begin
  FId := Value;
  Changed;
end;

procedure TksListItemRowObj.SetRect(const Value: TRectF);
begin
  FRect := Value;
  Changed;
end;

procedure TksListItemRowObj.SetVertAlign(const Value: TListItemAlign);
begin
  FVertAlignment := Value;
  Changed;
end;

// ------------------------------------------------------------------------------

{ TksListItemRowText }

constructor TksListItemRowText.Create(ARow: TKsListItemRow);
begin
  inherited Create(ARow);
  FFont := TFont.Create;
  FTextColor := claBlack;
  FWordWrap := False;
end;

destructor TksListItemRowText.Destroy;
begin
  FFont.Free;
  inherited;
end;

function TksListItemRowText.Render(ACanvas: TCanvas): Boolean;
begin
  Result := inherited Render(ACanvas);
  ACanvas.Fill.Color := FTextColor;
  ACanvas.Font.Assign(FFont);
  ACanvas.FillText(FRect, FText, FWordWrap, 1, [], FAlignment);
  Result := True;
end;

procedure TksListItemRowText.SetAlignment(const Value: TTextAlign);
begin
  FAlignment := Value;
  Changed;
end;

procedure TksListItemRowText.SetFont(const Value: TFont);
begin
  FFont.Assign(Value);
  Changed;
end;

procedure TksListItemRowText.SetText(const Value: string);
begin
  FText := Value;
  Changed;
end;

procedure TksListItemRowText.SetTextColor(const Value: TAlphaColor);
begin
  FTextColor := Value;
  Changed;
end;

procedure TksListItemRowText.SetWordWrap(const Value: Boolean);
begin
  FWordWrap := Value;
  Changed;
end;

// ------------------------------------------------------------------------------

{ TksListItemRowImage }

constructor TksListItemRowImage.Create(ARow: TKsListItemRow);
begin
  inherited Create(ARow);
  FBitmap := TBitmap.Create;
  FBitmap.OnChange := DoChanged;
end;

destructor TksListItemRowImage.Destroy;
begin
  FBitmap.Free;
  inherited;
end;

function TksListItemRowImage.Render(ACanvas: TCanvas): Boolean;
begin
  Result := inherited Render(ACanvas);
  ACanvas.DrawBitmap(FBitmap, RectF(0, 0, FBitmap.Width, FBitmap.Height),
    FRect, 1, True);
end;

procedure TksListItemRowImage.SetBitmap(const Value: TBitmap);
begin
  FBitmap.Assign(Value);
  FBitmap.BitmapScale := GetScreenScale;
  Changed;
end;

// ------------------------------------------------------------------------------

{ TksListItemRow }

procedure TKsListItemRow.CacheRow;
var
  ICount: integer;
  Image: TStyleObject;
  Controller: IListViewController;
  r: TRectF;
  AMargins: TBounds;
begin
  if FCached then
    Exit;

  AMargins := (Owner.Parent as TCustomListView).ItemSpaces;
  Supports(Owner.Parent, IListViewController, Controller);
  r := Controller.GetClientMargins;


  BeginUpdate;
  try
    Bitmap.Width := Round(RowWidth);
    Bitmap.Height := Round(RowHeight);

    Bitmap.Width := Bitmap.Width - Round((AMargins.Left + AMargins.Right) * GetScreenScale);
    Bitmap.Clear(claNull);
    Bitmap.Canvas.BeginScene;
    try
      if FIndicatorColor <> claNull then
      begin
        Bitmap.Canvas.Fill.Color := FIndicatorColor;
        Bitmap.Canvas.FillRect(RectF(0, 8, 6, RowHeight(False)-8), 0, 0, [], 1, Bitmap.Canvas.Fill);
      end;

      for ICount := 0 to FList.Count - 1 do
      begin
        FList[ICount].CalculateRect(Bitmap);
        if FList[ICount].Render(Bitmap.Canvas) = False then
        begin
          FCached := False;
          Exit;
        end;

      end;
      Bitmap.Canvas.Fill.Color := claRed;

      if FShowAccessory then
      begin

        FAccessory.CalculateRect(Bitmap);
        FAccessory.Render(Bitmap.Canvas);
        {Image := Resources.AccessoryImages[FAccessory].Normal;
        r := RectF(RowWidth(False), 0, RowWidth(False)+Image.Width, RowHeight(False));
        OffsetRect(r, 0 - (DefaultScrollBarWidth + ListView.ItemSpaces.Rect.Right), 0);
        OffsetRect(r, 0-ListView.ItemSpaces.Left, 0);
        //OffsetRect(r, (Bitmap.Width / GetScreenScale) - Image.Width, 0);
        //r := RectF((RowWidth(False) - Image.Width), 0, RowWidth(False) - (DefaultScrollBarWidth), RowHeight(False));

        //OffsetRect(r, 0-(ListView.ItemSpaces.Right + DefaultScrollBarWidth), 0);
        Image.DrawToCanvas(Bitmap.Canvas, r); }
      end;
    finally
      Bitmap.Canvas.EndScene;
    end;
    FCached := True;
  finally
    EndUpdate;
  end;
end;

constructor TKsListItemRow.Create(const AOwner: TListItem);
var
  ABmp: TBitmap;
begin
  inherited Create(AOwner);
{$IFDEF MSWINDOWS}

  ScalingMode := TImageScalingMode.Original;
{$ENDIF}
  PlaceOffset.X := 0;
  FIndicatorColor := claNull;
  OwnsBitmap := True;
  FList := TObjectList<TksListItemRowObj>.Create(True);
  FList.OnNotify := DoOnListChanged;
  ABmp := TBitmap.Create;
  ABmp.BitmapScale := GetScreenScale;
  ABmp.Width := Round(RowWidth);
  ABmp.Height := Round(RowHeight);
  ABmp.Clear(claNull);
  Bitmap := ABmp;
  FTextColor := claBlack;
  FFont := TFont.Create;
  FCached := False;
  FAccessory := TKsListItemRowAccessory.Create(Self);
  FShowAccessory := True;
end;

destructor TKsListItemRow.Destroy;
begin
  FList.Free;
  FFont.Free;
  FAccessory.Free;
  inherited;
end;

function TKsListItemRow.ScreenWidth: single;
begin
  Result := TksListView(Owner.Parent).Width;
{$IFDEF MSWINDOWS}
  Result := Result - 40;
{$ENDIF}
end;

function TKsListItemRow.TextHeight(AText: string): single;
begin
  Bitmap.Canvas.Font.Assign(FFont);
  Result := Bitmap.Canvas.TextHeight(AText);
end;

function TKsListItemRow.TextWidth(AText: string): single;
begin
  Bitmap.Canvas.Font.Assign(FFont);
  Result := Bitmap.Canvas.TextWidth(AText);
end;

function TKsListItemRow.RowHeight(const AScale: Boolean = True): single;
var
  lv: TksListView;
begin
  lv := TksListView(Owner.Parent);
  Result := lv.ItemAppearance.ItemHeight;
  if AScale then
    Result := Result * GetScreenScale;
end;

function TKsListItemRow.RowWidth(const AScale: Boolean = True): single;
var
  lv: TksListView;
begin
  lv := TksListView(Owner.Parent);
  Result := lv.Width;
  if AScale then
    Result := Result * GetScreenScale;
end;

function TKsListItemRow.GetAccessory: TAccessoryType;
begin
  Result := FAccessory.AccessoryType;
end;

function TKsListItemRow.GetListView: TCustomListView;
begin
  Result := (Owner.Parent as TCustomListView);
end;

function TKsListItemRow.GetRowObject(AIndex: integer): TksListItemRowObj;
begin
  Result := FList[AIndex];
end;

function TKsListItemRow.GetRowObjectCount: integer;
begin
  Result := FList.Count;
end;

procedure TKsListItemRow.DoOnListChanged(Sender: TObject;
  const Item: TksListItemRowObj; Action: TCollectionNotification);
begin
  FCached := False;
end;

// ------------------------------------------------------------------------------

// bitmap drawing functions...

function TKsListItemRow.DrawBitmap(ABmp: TBitmap; x, AWidth, AHeight: single): TksListItemRowImage;
begin
  Result := DrawBitmap(ABmp, x, 0, AWidth, AHeight);
end;

function TKsListItemRow.DrawBitmap(ABmpIndex: integer;
  x, AWidth, AHeight: single): TksListItemRowImage overload;
var
  ABmp: TBitmap;
  il: TCustomImageList;
  ASize: TSizeF;
begin
  il := ListView.Images;
  if il = nil then
    Exit;
  ASize.cx := 64;
  ASize.cy := 64;
  ABmp := il.Bitmap(ASize, ABmpIndex);
  Result := DrawBitmap(ABmp, x, AWidth, AHeight);
end;

function TKsListItemRow.DrawBitmap(ABmp: TBitmap; x, y, AWidth, AHeight: single)
  : TksListItemRowImage;
begin
  Result := TksListItemRowImage.Create(Self);
  Result.FRect := RectF(0, 0, AWidth, AHeight); //RectF(x, y, x + AWidth, y + AHeight);
  Result.PlaceOffset := PointF(x,y);
  Result.VertAlign := TListItemAlign.Center;
  Result.Bitmap := ABmp;
  FList.Add(Result);
end;

function TKsListItemRow.DrawBitmapRight(ABmp: TBitmap;
  AWidth, AHeight, ARightPadding: single): TksListItemRowImage;
var
  AYpos: single;
  AXPos: single;
begin
  AYpos := (RowHeight(False) - AHeight) / 2;
  AXPos := ScreenWidth - (AWidth + ARightPadding);
  Result := DrawBitmap(ABmp, AXPos, AYpos, AWidth, AHeight);
end;

function TKsListItemRow.AddSegmentButtons(AWidth, AXOffset: integer): TksListItemRowSegmentButtons;
var
  ABtn: TButton;
  AHeight: single;
begin
  ABtn := TButton.Create(nil);
  try
    AHeight := ABtn.Height;
  finally
    ABtn.Free;
  end;
  Result := TksListItemRowSegmentButtons.Create(Self);
  Result.Align := TListItemAlign.Trailing;
  Result.VertAlign := TListItemAlign.Center;
  Result.PlaceOffset := PointF(AXOffset, 0);
  Result.Rect := RectF(0, 0, AWidth, AHeight);
  ShowAccessory := False;
  FList.Add(Result);
end;

function TKsListItemRow.AddSwitch(x: single;
                                  AIsChecked: Boolean;
                                  const AAlign: TListItemAlign = TListItemAlign.Leading): TksListItemRowSwitch;
var
  s: TSwitch;
  ASize: TSize;
  ARect: TRectF;
begin
  Result := TksListItemRowSwitch.Create(Self);
  Result.Align := AAlign;

  Result.PlaceOffset := PointF(x, 0);

  s := TSwitch.Create(nil);
  try
    Result.FRect := RectF(0, 0, s.Width, s.Height);
  finally
    s.Free;
  end;
  //
  //Result.CalculateRect(;

  Result.IsChecked := AIsChecked;
  FList.Add(Result);
end;

function TksListItemRow.AddSwitchRight(AMargin: integer; AIsChecked: Boolean): TksListItemRowSwitch;
begin
  Result := AddSwitch(AMargin, AIsChecked, TListItemAlign.Trailing)
end;

procedure TKsListItemRow.SetAccessory(const Value: TAccessoryType);
begin
  FAccessory.AccessoryType := Value;
end;

procedure TKsListItemRow.SetFontProperties(AName: string; ASize: integer;
  AColor: TAlphaColor; AStyle: TFontStyles);
begin
  if AName <> '' then
    FFont.Family := AName;
  FFont.Size := ASize;
  FTextColor := AColor;
  FFont.Style := AStyle;
end;

procedure TKsListItemRow.SetShowAccessory(const Value: Boolean);
begin
  FShowAccessory := Value;
  FCached := False;
end;

// ------------------------------------------------------------------------------

// text drawing functions...

function TKsListItemRow.TextOut(AText: string; x: single;
  const AVertAlign: TTextAlign = TTextAlign.Center;
  const AWordWrap: Boolean = False): TksListItemRowText;
var
  AWidth: single;
begin
  AWidth := TextWidth(AText);
  Result := TextOut(AText, x, AWidth, AVertAlign, AWordWrap);
end;

function TKsListItemRow.TextOut(AText: string; x, AWidth: single;
  const AVertAlign: TTextAlign = TTextAlign.Center;
  const AWordWrap: Boolean = False): TksListItemRowText;
begin
  Result := TextOut(AText, x, 0, AWidth, AVertAlign, AWordWrap);
end;


function TKsListItemRow.TextOut(AText: string; x, y, AWidth: single;
  const AVertAlign: TTextAlign = TTextAlign.Center;
  const AWordWrap: Boolean = False): TksListItemRowText;
var
  AHeight: single;

begin
  Result := TksListItemRowText.Create(Self);
  AHeight := TextHeight(AText);
  Result.FPlaceOffset := PointF(x, y);
  if AWordWrap then
    AHeight := RowHeight(False);
  Result.FRect := RectF(0, 0, AWidth, AHeight);
  case AVertAlign of
    TTextAlign.Leading: Result.VertAlign := TListItemAlign.Leading;
    TTextAlign.Center: Result.VertAlign := TListItemAlign.Center;
    TTextAlign.Trailing: Result.VertAlign := TListItemAlign.Trailing;
  end;
  Result.Font.Assign(FFont);
  Result.TextAlignment := TTextAlign.Leading;
  Result.TextColor := FTextColor;
  Result.Text := AText;
  Result.WordWrap := AWordWrap;
  FList.Add(Result);
end;

function TKsListItemRow.TextOutRight(AText: string; y, AWidth: single;
  AXOffset: single; const AVertAlign: TTextAlign = TTextAlign.Center)
  : TksListItemRowText;
begin
  Result := TextOut(AText, AXOffset, y, AWidth, AVertAlign);
  Result.Align := TListItemAlign.Trailing;
  Result.TextAlignment := TTextAlign.Trailing;
end;


// ------------------------------------------------------------------------------

{ TksListViewAppearence }

constructor TksListViewAppearence.Create(AListView: TksListView);
begin
  inherited Create;
  FListView := AListView;
  FBackground := claWhite;
  FItemBackground := claWhite;
  FAlternatingItemBackground := claGainsboro;
end;

procedure TksListViewAppearence.SetAlternatingItemBackground
  (const Value: TAlphaColor);
begin
  FAlternatingItemBackground := Value;
  FListView.ApplyStyle;
end;

procedure TksListViewAppearence.SetBackground(const Value: TAlphaColor);
begin
  FBackground := Value;
  FListView.ApplyStyle;
end;

procedure TksListViewAppearence.SetItemBackground(const Value: TAlphaColor);
begin
  FItemBackground := Value;
  FListView.ApplyStyle;
end;

// ------------------------------------------------------------------------------

{ TksListView }

constructor TksListView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FScreenScale := GetScreenScale;
  FAppearence := TksListViewAppearence.Create(Self);
  FItemHeight := 44;
  FClickTimer := TTimer.Create(Self);
  FLastWidth := 0;
  FSelectOnRightClick := False;
  FCacheTimer := TTimer.Create(Self);
  FCacheTimer.Interval := 100;
  FCacheTimer.OnTimer := OnCacheTimer;
  FCacheTimer.Enabled := True;
  FLastScrollPos := 0;

  FScrolling := False;
  FScrollTimer := TTimer.Create(Self);
  FScrollTimer.Interval := 500;
  FScrollTimer.OnTimer := DoScrollTimer;
  FScrollTimer.Enabled := True;


end;

destructor TksListView.Destroy;
begin
  FAppearence.Free;
  FClickTimer.Free;
  FCacheTimer.Free;
  FScrollTimer.Free;
  FSwitchBmp[0].Free;
  FSwitchBmp[1].Free;
  inherited;
end;

function TksListView.AddHeader(AText: string): TKsListItemRow;
begin
  Result := AddRow('', TListItemPurpose.Header, '');
  Result.Font.Style := [];
  Result.TextColor := claSilver;
  Result.Font.Size := 16;
  Result.TextOut(AText, 0, 0, Result.TextWidth(AText), TTextAlign.Trailing);
  Result.CacheRow;
end;

function TksListView.AddRow(const ASearchIndex: string = '';
  const APurpose: TListItemPurpose = TListItemPurpose.None;
  const AId: string = ''): TKsListItemRow;
var
  AItem: TListViewItem;
  AIndex: string;
begin
  AItem := Items.Add;
  AItem.Height := ItemHeight;
  AIndex := ASearchIndex;

  if AIndex = '' then
    AIndex := ' ';
  AItem.Text := AIndex;
  AItem.Objects.Clear;
  AItem.Purpose := APurpose;
  Result := TKsListItemRow.Create(AItem);
  Result.ShowAccessory := APurpose = TListItemPurpose.None;
  Result.Name := 'ksRow';
  Result.ID := AId;
end;

procedure TksListView.SetColorStyle(AName: string; AColor: TAlphaColor);
var
  StyleObject: TFmxObject;
begin
  StyleObject := FindStyleResource(AName);
  if StyleObject <> nil then
  begin
    (StyleObject as TColorObject).Color := AColor;
    Invalidate;
  end;
end;

procedure TksListView.SetItemHeight(const Value: integer);
var
  ICount: integer;
  ARow: TKsListItemRow;
begin
  BeginUpdate;
  try
    FItemHeight := Value;
    RedrawAllRows;
  finally
    ItemAppearance.ItemHeight := Value;
    EndUpdate;
  end;
  Repaint;
end;

procedure TksListView.ApplyStyle;
var
  StyleObject: TFmxObject;
begin
  SetColorStyle('background', FAppearence.Background);
  SetColorStyle('itembackground', FAppearence.ItemBackground);
  SetColorStyle('alternatingitembackground',
    FAppearence.AlternatingItemBackground);
  inherited;
end;

procedure TksListView.DoClickTimer(Sender: TObject);
var
  ARow: TKsListItemRow;
  AId: string;
  AMouseDownRect: TRectF;
begin
  if FClickedItem = nil then
  begin
    FClickTimer.Enabled := False;
    FMouseDownDuration := 0;
    Exit;
  end;

  FMouseDownDuration := FMouseDownDuration + 1;
  AId := '';
  ARow := nil;
  if FMouseDownDuration >= C_LONG_TAP_DURATION  then
  begin
    FClickTimer.Enabled := False;

    ARow := FClickedItem.Objects.FindObject('ksRow') as TKsListItemRow;
    if ARow <> nil then
      AId := ARow.ID;
    AMouseDownRect := RectF(FMouseDownPos.X-8, FMouseDownPos.Y-8, FMouseDownPos.X+8, FMouseDownPos.Y+8);
    if PtInRect(AMouseDownRect, FCurrentMousepos) then
    begin
      if Assigned(FOnLongClick) then
        FOnLongClick(Self, FMouseDownPos.x, FMouseDownPos.y, FClickedItem, AId, FClickedRowObj);
    end;
    ItemIndex := -1;
  end;
end;


procedure TksListView.DoItemClick(const AItem: TListViewItem);
begin
  inherited;
end;

procedure TksListView.DoScrollTimer(Sender: TObject);
var
  AVisibleItems: TksVisibleItems;
begin

  if FScrolling = False then
  begin
    if Trunc(ScrollViewPos) <> FLastScrollPos then
    begin
      FScrolling := True;
      FLastScrollPos := Trunc(ScrollViewPos);
      Exit;
    end;
  end
  else
  begin
    if FLastScrollPos = Trunc(ScrollViewPos) then
    begin
      FScrolling := False;
      if Assigned(FOnFinishScrolling) then
      begin
        AVisibleItems := ItemsInView;
        FOnFinishScrolling(Self, AVisibleItems.IndexStart, AVisibleItems.Count);
      end;
    end;
  end;
  FLastScrollPos := Trunc(ScrollViewPos);
end;

procedure TksListView.MouseUp(Button: TMouseButton; Shift: TShiftState; x,
  y: single);
var
  AId: string;
  ARow: TKsListItemRow;
  ICount: integer;
  AObjRect: TRectF;
  AMouseDownRect: TRect;
  ALongTap: Boolean;
begin
  inherited;
  FClickTimer.Enabled := False;
  ALongTap := FMouseDownDuration >= C_LONG_TAP_DURATION ;
  FMouseDownDuration := 0;

  AMouseDownRect := Rect(Round(FMouseDownPos.X-8), Round(FMouseDownPos.Y-8), Round(FMouseDownPos.X+8), Round(FMouseDownPos.Y+8));
  if not PtInRect(AMouseDownRect, Point(Round(x),Round(y))) then
    Exit;


  if FClickedItem <> nil then
  begin
    AId := '';
    ARow := FClickedItem.Objects.FindObject('ksRow') as TKsListItemRow;
    if ARow <> nil then
    begin
      AId := ARow.ID;
      for ICount := 0 to ARow.RowObjectCount - 1 do
      begin
        AObjRect := ARow.RowObject[ICount].Rect;
        if (FMouseDownPos.x >= (AObjRect.Left - 5)) and
          (FMouseDownPos.x <= (AObjRect.Right + 5)) then
        begin
          FClickedRowObj := ARow.RowObject[ICount];
        end;
      end;
    end;
    if not ALongTap then
    begin
      // normal click.
      if Button = TMouseButton.mbLeft then
      begin
        if Assigned(FOnItemClickEx) then
          FOnItemClickEx(Self, FMouseDownPos.x, FMouseDownPos.y, FClickedItem, AId, FClickedRowObj)
      else
        if Assigned(FOnItemRightClickEx) then
          FOnItemRightClickEx(Self, FMouseDownPos.x, FMouseDownPos.y, FClickedItem, AId, FClickedRowObj);
      end;
      if FClickedRowObj <> nil then
      begin
        FClickedRowObj.Click(FMouseDownPos.X - FClickedRowObj.Rect.Left, FMouseDownPos.Y - FClickedRowObj.Rect.Top);
        if (FClickedRowObj is TksListItemRowSwitch) then
        begin
          (FClickedRowObj as TksListItemRowSwitch).Toggle;
          if Assigned(FOnSwitchClicked) then
            FOnSwitchClicked(Self, FClickedItem, (FClickedRowObj as TksListItemRowSwitch), AId);
        end;
        ARow.CacheRow;
        Invalidate;
      end;
    end;
  end;
end;




procedure TksListView.OnCacheTimer(Sender: TObject);
begin
  FCacheTimer.Enabled := False;
  StoreSwitchImages;
  if FSwitchBmp[0] <> nil then
  begin
    FCacheTimer.Enabled := False;
    RedrawAllRows;
  end
  else
    FCacheTimer.Enabled := True;
end;

procedure TksListView.RedrawAllRows;
var
  ICount: integer;
  ARow: TKsListItemRow;
begin
  for ICount := 0 to Items.Count - 1 do
  begin
    ARow := Items[ICount].Objects.FindObject('ksRow') as TKsListItemRow;
    if ARow <> nil then
    begin
      ARow.Cached := False;
      ARow.CacheRow;
    end;
  end;
  Invalidate;
end;


procedure TksListView.Resize;
begin
  inherited;
  RedrawAllRows;
end;

procedure TksListView.EndUpdate;
var
  ICount: integer;
  AItem: TListViewItem;
  ARow: TKsListItemRow;
  ARowObj: TKsListItemRow;
begin
  inherited EndUpdate;
  Application.ProcessMessages;
  for ICount := 0 to Items.Count - 1 do
  begin
    AItem := Items[ICount];
    ARow := AItem.Objects.FindObject('ksRow') as TKsListItemRow;
    if ARow <> nil then
      ARow.CacheRow;
  end;
  Invalidate;
end;

function TksListView.GetCachedRow(index: integer): TKsListItemRow;
begin
  Result := Items[index].Objects.FindObject('ksRow') as TKsListItemRow;
end;


function TksListView.GetSwitchImage(AIsChecked: Boolean): TBitmap;
begin
  case AIsChecked of
    False: Result := FSwitchBmp[0];
    True: Result := FSwitchBmp[1];
  end;
end;

procedure TksListView.StoreSwitchImages;
var
  ASwitch: TSwitch;
  ABlank: TBitmap;
begin
  if FSwitchBmp[0] <> nil then
    Exit;
  ASwitch := TSwitch.Create(Self);
  try
    ASwitch.IsChecked := False;
    AddObject(ASwitch);
    Application.ProcessMessages;
    FSwitchBmp[0] := ASwitch.MakeScreenshot;
    ABlank := TBitmap.Create(FSwitchBmp[0].Width, FSwitchBmp[0].Height);
    ABlank.Clear(claNull);
    try
      if FSwitchBmp[0].EqualsBitmap(ABlank) then
      begin
        FSwitchBmp[0].Free;
        FSwitchBmp[0] := nil;
        Exit;
      end;
    finally
      ABlank.Free;
    end;
    Application.ProcessMessages;
    ASwitch.IsChecked := True;
    FSwitchBmp[1] := ASwitch.MakeScreenshot;
  finally
    RemoveObject(ASwitch);
    ASwitch.Free;
  end;
end;

procedure TksListView.Invalidate;
begin
  inherited;

end;

function TksListView.ItemsInView: TksVisibleItems;
var
  ICount: integer;
  ARect: TRectF;
  r: TRectF;
  cr: TRectF;
  ASearchHeight: integer;
  ASearchBox: TSearchBox;
begin
  cr := RectF(0, 0, Width, Height);;
  if SearchVisible then
  begin
    ASearchBox := TSearchBox.Create(nil);
    try
      ASearchHeight := Round(ASearchBox.Height);
    finally
      ASearchBox.Free;
    end;
    cr.Top := ASearchHeight;
  end;
  Result.IndexStart := -1;
  Result.IndexEnd := -1;
  Result.Count := 0;

  for ICount := 0 to Items.Count-1 do
  begin
    if IntersectRectF(r, GetItemRect(ICount), cr) then
    begin
      if Result.IndexStart = -1 then
        Result.IndexStart := ICount
      else
        Result.IndexEnd := ICount;
      Result.Count := Result.Count + 1;
    end;
  end;
end;

procedure TksListView.MouseDown(Button: TMouseButton; Shift: TShiftState;
  x, y: single);
var
  ICount: integer;
begin
//{$IFDEF MSWINDOWS}
//  FMouseDownPos := PointF(x - 10, y);
//{$ELSE}
  FMouseDownPos := PointF(x, y);
//{$ENDIF}
  FClickedItem := nil;
  FClickedRowObj := nil;

  FCurrentMousepos := FMouseDownPos;
  FMouseDownDuration := 0;
  for Icount := 0 to Items.Count-1 do
  begin
    if PtInRect(GetItemRect(ICount), PointF(x,y)) then
    begin
      FClickedItem := Items[ICount];
      if (Button = TMouseButton.mbRight) and (FSelectOnRightClick) then
        ItemIndex := Icount;
    end;
  end;
  inherited;
  Application.ProcessMessages;
  FClickTimer.Interval := 100;
  FClickTimer.OnTimer := DoClickTimer;
  FClickTimer.Enabled := True;
end;

procedure TksListView.MouseMove(Shift: TShiftState; X, Y: Single);
begin
  inherited;
  //{$IFDEF MSWINDOWS}
  //  FCurrentMousepos := PointF(x - 10, y);
  //{$ELSE}
    FCurrentMousepos := PointF(x, y);
  //{$ENDIF}
end;

{ TksListItemRowSwitch }

function TksListItemRowSwitch.Render(ACanvas: TCanvas): Boolean;
var
  AWidth, AHeight: single;
  ABmp: TBitmap;
  ASwitch: TSwitch;
  r: TRectF;
  lv: TksListView;
  b: TBitmap;
begin
  Result := inherited Render(ACanvas);
  lv := (FRow.Owner.Parent as TksListView);
  b := lv.GetSwitchImage(FIsChecked);
  if b <> nil then
    ACanvas.DrawBitmap(b, RectF(0,0,b.Width,b.Height), FRect, 1, True)
  else
    Result := False;
end;

procedure TksListItemRowSwitch.SetIsChecked(const Value: Boolean);
begin
  FIsChecked := Value;
  Changed;
end;

procedure TksListItemRowSwitch.Toggle;
begin
  IsChecked := not IsChecked;
end;

{ TKsListItemRowAccessory }

constructor TKsListItemRowAccessory.Create(ARow: TKsListItemRow);
begin
  inherited;
  FResources := FRow.GetStyleResources;
  FImage := FResources.AccessoryImages[FAccessoryType].Normal;
  FRect := RectF(0, 0, FImage.Width, FImage.Height);
  FAlign := TListItemAlign.Trailing;
  FVertAlignment := TListItemAlign.Center
end;

function TKsListItemRowAccessory.Render(ACanvas: TCanvas): Boolean;
begin
  Result := inherited Render(ACanvas);

  FImage.DrawToCanvas(ACanvas, FRect, 1);
end;

procedure TKsListItemRowAccessory.SetAccessoryType(const Value: TAccessoryType);
begin
  FAccessoryType := Value;
  Changed;
end;

{ TksListItemRowSegmentButtons }

procedure TksListItemRowSegmentButtons.Click(x, y: single);
var
  ABtnWidth: single;
begin
  inherited;
  ABtnWidth := FRect.Width / FCaptions.Count;
  ItemIndex := Trunc(x / ABtnWidth);
  //Application.MainForm.Caption := floattostr(AIndex);
end;

constructor TksListItemRowSegmentButtons.Create(ARow: TKsListItemRow);
begin
  inherited;
  FCaptions := TStringList.Create;
  FCaptions.Add('One');
  FCaptions.Add('Two');
  FCaptions.Add('Three');
  FItemIndex := -1;
end;

destructor TksListItemRowSegmentButtons.Destroy;
begin
  FCaptions.Free;
  inherited;
end;

function TksListItemRowSegmentButtons.Render(ACanvas: TCanvas): Boolean;
var
  ABmp: TBitmap;
  AButton: TSpeedButton;
  r: TRectF;
  lv: TksListView;
  b: TBitmap;
  ABlank: TBitmap;
  ABtnWidth: single;
  ICount: integer;
  AXPos: single;
  ARect: TRectF;
  AGroup: string;
begin
  AGroup := 'group_'+IntToStr(TListViewItem(FRow.Owner).Index);
  Result := inherited Render(ACanvas);
  lv := (FRow.Owner.Parent as TksListView);

  ABtnWidth := FRect.Width / FCaptions.Count;
  AXPos := FRect.Left;
  for ICount := 0 to FCaptions.Count-1 do
  begin
    if FItemIndex = -1 then
      FItemIndex := 0;
    AButton := TSpeedButton.Create(lv.Parent);
    AButton.Text := FCaptions[ICount];
    AButton.SetBounds(0, 0, ABtnWidth, FRect.Height);
    if ICount = 0 then AButton.StyleLookup := 'segmentedbuttonleft';
    if ICount > 0 then AButton.StyleLookup := 'segmentedbuttonmiddle';
    if ICount = FCaptions.Create.Count-1 then AButton.StyleLookup := 'segmentedbuttonright';

    AButton.GroupName := AGroup;
    AButton.StaysPressed := True;

    //AButton.Visible := False;
    lv.Parent.InsertObject(0, AButton);
    AButton.IsPressed := FItemIndex = ICount;
    Application.ProcessMessages;
    b := AButton.MakeScreenshot;
    ARect := RectF(AXPos, FRect.Top, AXPos+ABtnWidth, FRect.Bottom);
    ACanvas.DrawBitmap(b, RectF(0,0,b.Width,b.Height), ARect, 1, True);
    AXPos := AXPos + ABtnWidth;
    b.Free;
    lv.Parent.RemoveObject(AButton);
    AButton.Free;
  end;
end;

procedure TksListItemRowSegmentButtons.SetItemIndex(const Value: integer);
begin
  if FItemIndex = Value then
    Exit;
  FItemIndex := Value;
  Changed;
end;

end.

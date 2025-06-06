{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2023 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit WiRL.Core.MessageBody.Default;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,

  WiRL.Core.JSON,
  WiRL.Core.Classes,
  WiRL.Core.Attributes,
  WiRL.Core.Declarations,
  WiRL.http.Core,
  WiRL.http.Headers,
  WiRL.http.Request,
  WiRL.http.Response,
  WiRL.http.Accept.MediaType,
  WiRL.Core.Context,
  WiRL.Core.MessageBodyWriter,
  WiRL.Core.MessageBodyReader,
  WiRL.Core.MessageBody.Classes,
  WiRL.Core.Exceptions,
  WiRL.Configuration.Core,
  WiRL.Configuration.Neon,
  WiRL.Configuration.Converter;

type
  /// <summary>
  ///   This component force the inclusion of the current unit
  /// </summary>
  TWiRLMBWDefaultProvider = class(TComponent)
  end;

  /// <summary>
  ///   This is the <b>default</b> MessageBodyWriter for all Delphi string types.
  /// </summary>
  [Produces(TMediaType.WILDCARD)]
  [Consumes(TMediaType.WILDCARD)]
  TWiRLStringProvider = class(TMessageBodyProvider)
  public
    function ReadFrom(AType: TRttiType; AMediaType: TMediaType;
      AHeaders: IWiRLHeaders; AContentStream: TStream): TValue; override;

    procedure WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream); override;
  end;

  /// <summary>
  ///   This is the <b>default</b> MessageBodyWriter for all Delphi simple types: integer,
  ///   double, etc...
  /// </summary>
  [Produces(TMediaType.TEXT_PLAIN)]
  [Consumes(TMediaType.TEXT_PLAIN)]
  TWiRLSimpleTypesProvider = class(TMessageBodyProvider)
  private
    [Context] FFormatSettingConfig: TWiRLFormatSettingConfig;
  public
    function ReadFrom(AType: TRttiType; AMediaType: TMediaType;
      AHeaders: IWiRLHeaders; AContentStream: TStream): TValue; override;

    procedure WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream); override;
  end;

  /// <summary>
  ///   Base class for the JSON-based providers. Contains the routines to write
  ///   the JSON or JSONP to the stream
  /// </summary>
  TWiRLJSONProvider = class(TMessageBodyProvider)
  private
    //[Context] FRequest: TWiRLRequest;
    [Context] FContext: TWiRLContextHttp;
    [Context] FConfigurationNeon: TWiRLConfigurationNeon;
  protected
    procedure WriteJSONToStream(AJSON: TJSONValue; AStream: TStream);
    procedure WriteJSONPToStream(AJSON: TJSONValue; AStream: TStream);
  end;

  /// <summary>
  ///   This is the <b>default</b> MessageBodyProvider for Delphi array and record types
  /// </summary>
  [Consumes(TMediaType.APPLICATION_JSON)]
  [Produces(TMediaType.APPLICATION_JSON)]
  [Produces(TMediaType.APPLICATION_JAVASCRIPT)]
  TWiRLValueTypesProvider = class(TWiRLJSONProvider)
  private
    [Context] WiRLConfigurationNeon: TWiRLConfigurationNeon;
  public
    function ReadFrom(AType: TRttiType; AMediaType: TMediaType;
      AHeaders: IWiRLHeaders; AContentStream: TStream): TValue; override;

    procedure WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream); override;
  end;

  /// <summary>
  ///   This is the standard TObject MessageBodyReader/Writer and is using the WiRL Persistence library
  ///   (Neon Library).
  /// </summary>
  [Consumes(TMediaType.APPLICATION_JSON)]
  [Produces(TMediaType.APPLICATION_JSON)]
  [Produces(TMediaType.APPLICATION_JAVASCRIPT)]
  TWiRLObjectProvider = class(TWiRLJSONProvider)
  private
    [Context] WiRLConfigurationNeon: TWiRLConfigurationNeon;
  public
    function ReadFrom(AType: TRttiType; AMediaType: TMediaType;
      AHeaders: IWiRLHeaders; AContentStream: TStream): TValue; overload; override;

    procedure ReadFrom(AObject: TObject; AType: TRttitype; AMediaType: TMediaType;
	    AHeaders: IWiRLHeaders; AContentStream: TStream); overload; override;

    procedure WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream); override;
  end;

  /// <summary>
  ///   This is the standard JSONValue MessageBodyReader/Writer using the Delphi JSON library.
  /// </summary>
  [Consumes(TMediaType.APPLICATION_JSON)]
  [Produces(TMediaType.APPLICATION_JSON)]
  [Produces(TMediaType.APPLICATION_JAVASCRIPT)]
  TWiRLJSONValueProvider = class(TWiRLJSONProvider)
  public
    function ReadFrom(AType: TRttiType; AMediaType: TMediaType;
      AHeaders: IWiRLHeaders; AContentStream: TStream): TValue; override;

    procedure WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream); override;

    function AsObject: TObject;
  end;

  /// <summary>
  ///   This is the standard TStream MessageBodyReader/Writer using the Delphi TStream methods
  /// </summary>
  [Consumes(TMediaType.APPLICATION_OCTET_STREAM), Consumes(TMediaType.WILDCARD)]
  [Produces(TMediaType.APPLICATION_OCTET_STREAM), Produces(TMediaType.WILDCARD)]
  TWiRLStreamProvider = class(TMessageBodyProvider)
  public
    function ReadFrom(AType: TRttiType; AMediaType: TMediaType;
      AHeaders: IWiRLHeaders; AContentStream: TStream): TValue; override;

    procedure ReadFrom(AObject: TObject; AType: TRttiType;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream);
      override;

    procedure WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream); override;
  end;

  /// <summary>
  ///   This is the standard TMultipartFormData MessageBodyWriter
  /// </summary>
  {$IFNDEF HAS_NETHTTP_CLIENT}
  [Produces(TMediaType.MULTIPART_FORM_DATA)]
  TWiRLMultipartFormDataProvider = class(TMessageBodyProvider)
  public
    procedure WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream); override;
  end;
  {$ENDIF}

  /// <summary>
  ///   This is the MessageBodyWriter for all TWiRLStreamingResponse descendant
  /// </summary>
  [Produces(TMediaType.WILDCARD)]
  TWiRLStreamingResponseProvider = class(TMessageBodyProvider)
  private
    [Context]
    FContext: TWiRLContextHttp;
  public
    function ReadFrom(AType: TRttiType; AMediaType: TMediaType;
      AHeaders: IWiRLHeaders; AContentStream: TStream): TValue; override;

    procedure WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream); override;
  end;


implementation

uses
  {$IFNDEF HAS_NETHTTP_CLIENT}
  System.Net.Mime,
  {$ENDIF}
  System.TypInfo,
  WiRL.Core.Utils,
  WiRL.Core.Converter,
  WiRL.Rtti.Utils,
  Neon.Core.Persistence,
  Neon.Core.Persistence.JSON;

{ TWiRLStringProvider }

function TWiRLStringProvider.ReadFrom(AType: TRttiType; AMediaType: TMediaType;
  AHeaders: IWiRLHeaders; AContentStream: TStream): TValue;
var
  LStreamReader: TStreamReader;
  LEncoding: TEncoding;
begin
  LEncoding := AMediaType.GetDelphiEncoding;
  try
    AContentStream.Position := 0;
    LStreamReader := TStreamReader.Create(AContentStream, LEncoding);
    try
      Result := LStreamReader.ReadToEnd;
    finally
      LStreamReader.Free;
    end;
  finally
    LEncoding.Free;
  end;
end;

procedure TWiRLStringProvider.WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream);
var
  LStreamWriter: TStreamWriter;
  LEncoding: TEncoding;
begin
  LEncoding := AMediaType.GetDelphiEncoding;

  LStreamWriter := TStreamWriter.Create(AContentStream, LEncoding);
  try
    case AValue.Kind of
      tkChar,
      tkWChar,
      tkString,
      tkUString,
      tkLString,
      tkWString: LStreamWriter.Write(AValue.AsType<string>);
    end;
  finally
    LStreamWriter.Free;
    LEncoding.Free;
  end;
end;

{ TWiRLJSONValueProvider }

function TWiRLJSONValueProvider.AsObject: TObject;
begin
  Result := Self;
end;

function TWiRLJSONValueProvider.ReadFrom(AType: TRttiType; AMediaType: TMediaType;
      AHeaders: IWiRLHeaders; AContentStream: TStream): TValue;
begin
  Result := TJSONObject.ParseJSONValue(ContentStreamToString(AMediaType.Charset, AContentStream));
end;

procedure TWiRLJSONValueProvider.WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream);
var
  LJSONValue: TJSONValue;
begin
  LJSONValue := AValue.AsObject as TJSONValue;
  if Assigned(LJSONValue) then
  begin
    if AMediaType.IsType(TMediaType.APPLICATION_JAVASCRIPT) then
      WriteJSONPToStream(LJSONValue, AContentStream)
    else
      WriteJSONToStream(LJSONValue, AContentStream);
  end;
end;

{ TWiRLSimpleTypesProvider }

function TWiRLSimpleTypesProvider.ReadFrom(AType: TRttiType;
  AMediaType: TMediaType; AHeaders: IWiRLHeaders;
  AContentStream: TStream): TValue;
var
  LStreamReader: TStreamReader;
  LFormatSetting: string;
  LEncoding: TEncoding;
  LStringValue: string;
begin
  LFormatSetting := FFormatSettingConfig.GetFormatSettingFor(AType.Handle);

  LEncoding := AMediaType.GetDelphiEncoding;
  try

    AContentStream.Position := 0;
    LStreamReader := TStreamReader.Create(AContentStream, LEncoding);
    try
      LStringValue := LStreamReader.ReadToEnd;
    finally
      LStreamReader.Free;
    end;

    Result := TWiRLConvert.AsType(LStringValue, AType.Handle, LFormatSetting);

  finally
    LEncoding.Free;
  end;
end;

procedure TWiRLSimpleTypesProvider.WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream);
var
  LFormatSetting: string;
  LEncoding: TEncoding;
  LStringValue: string;
  LBytes: TBytes;
begin
  LFormatSetting := FFormatSettingConfig.GetFormatSettingFor(AValue.TypeInfo);

  LEncoding := AMediaType.GetDelphiEncoding;
  try
    LStringValue := TWiRLConvert.From(AValue, AValue.TypeInfo, LFormatSetting);
    LBytes := LEncoding.GetBytes(LStringValue);
    AContentStream.Write(LBytes[0], Length(LBytes));
  finally
    LEncoding.Free;
  end;
end;

{ TWiRLValueTypesProvider }

function TWiRLValueTypesProvider.ReadFrom(AType: TRttiType; AMediaType: TMediaType;
      AHeaders: IWiRLHeaders; AContentStream: TStream): TValue;
var
  LDes: TNeonDeserializerJSON;
  LJSON: TJSONValue;
  LValue: TValue;
begin
  LDes := TNeonDeserializerJSON.Create(WiRLConfigurationNeon.GetNeonConfig);
  try
    LJSON := TJSONObject.ParseJSONValue(ContentStreamToString(AMediaType.Charset, AContentStream));
    try
      TValue.Make(nil, AType.Handle, LValue);
      Result := LDes.JSONToTValue(LJSON, AType, LValue);
    finally
      LJSON.Free;
    end;
  finally
    LDes.Free;
  end;
end;

procedure TWiRLValueTypesProvider.WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream);
var
  LJSON: TJSONValue;
begin
  case AValue.Kind of
    tkArray,
    tkDynArray,
    tkRecord:
    begin
      LJSON := TNeon.ValueToJSON(AValue, WiRLConfigurationNeon.GetNeonConfig);
      try
        if AMediaType.IsType(TMediaType.APPLICATION_JAVASCRIPT) then
          WriteJSONPToStream(LJSON, AContentStream)
        else
          WriteJSONToStream(LJSON, AContentStream);
      finally
        LJSON.Free;
      end;
    end;
  end;
end;

{ TWiRLObjectProvider }

function TWiRLObjectProvider.ReadFrom(AType: TRttiType; AMediaType: TMediaType;
      AHeaders: IWiRLHeaders; AContentStream: TStream): TValue;
begin
  Result := TNeon.JSONToObject(AType, ContentStreamToString(AMediaType.Charset, AContentStream), WiRLConfigurationNeon.GetNeonConfig);
end;

procedure TWiRLObjectProvider.ReadFrom(AObject: TObject; AType: TRttitype;
  AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream);
begin
  TNeon.JSONToObject(AObject, ContentStreamToString(AMediaType.Charset, AContentStream), WiRLConfigurationNeon.GetNeonConfig);
end;

procedure TWiRLObjectProvider.WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream);
var
  LJSON: TJSONValue;
begin
  LJSON := TNeon.ObjectToJSON(AValue.AsObject, WiRLConfigurationNeon.GetNeonConfig);
  try
    if AMediaType.IsType(TMediaType.APPLICATION_JAVASCRIPT) then
      WriteJSONPToStream(LJSON, AContentStream)
    else
      WriteJSONToStream(LJSON, AContentStream);
  finally
    LJSON.Free;
  end;
end;

{ TWiRLStreamProvider }

function TWiRLStreamProvider.ReadFrom(AType: TRttiType; AMediaType: TMediaType;
      AHeaders: IWiRLHeaders; AContentStream: TStream): TValue;
begin
  Result := AContentStream
end;

procedure TWiRLStreamProvider.ReadFrom(AObject: TObject; AType: TRttiType;
  AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream);
var
  LStream: TStream;
begin
  LStream := AObject as TStream;
  if Assigned(LStream) then
  begin
    AContentStream.Position := 0;
    LStream.CopyFrom(AContentStream, AContentStream.Size);
  end;
end;

procedure TWiRLStreamProvider.WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AHeaders: IWiRLHeaders; AContentStream: TStream);
var
  LStream: TStream;
begin
  if (not AValue.IsEmpty) and AValue.IsInstanceOf(TStream) then
  begin
    LStream := AValue.AsObject as TStream;
    if Assigned(LStream) then
      AContentStream.CopyFrom(LStream, LStream.Size);
  end;
end;

{ RegisterMessageBodyClasses }

procedure RegisterMessageBodyClasses;
begin
  // TWiRLStringProvider
  TMessageBodyWriterRegistry.Instance.RegisterWriter(
    TWiRLStringProvider,
    function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Boolean
    begin
      Result := False;
      case AType.TypeKind of
        tkChar, tkString, tkWChar, tkLString,
        tkWString, tkUString: Result := True;
      end;
    end,
    function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Integer
    begin
      Result := TMessageBodyWriterRegistry.AFFINITY_VERY_LOW;
    end
  );

  TMessageBodyReaderRegistry.Instance.RegisterReader(
    TWiRLStringProvider,
    function(AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Boolean
    begin
      Result := False;
      case AType.TypeKind of
        tkChar, tkString, tkWChar, tkLString,
        tkWString, tkUString: Result := True;
      end;
    end,
    function(AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Integer
    begin
      Result := TMessageBodyWriterRegistry.AFFINITY_VERY_LOW;
    end
  );


  // TWiRLSimpleTypesProvider
  TMessageBodyWriterRegistry.Instance.RegisterWriter(
    TWiRLSimpleTypesProvider,
    function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Boolean
    begin
      Result := False;
      case AType.TypeKind of
        tkUnknown, tkInteger, tkChar, tkEnumeration,
        tkFloat, tkSet, tkVariant, tkInt64: Result := True;
      end;
    end,
    function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Integer
    begin
      Result := TMessageBodyWriterRegistry.AFFINITY_VERY_LOW;
    end
  );

  TMessageBodyReaderRegistry.Instance.RegisterReader(
    TWiRLSimpleTypesProvider,
    function(AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Boolean
    begin
      Result := False;
      case AType.TypeKind of
        tkUnknown, tkInteger, tkChar, tkEnumeration,
        tkFloat, tkSet, tkVariant, tkInt64: Result := True;
      end;
    end,
    function(AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Integer
    begin
      Result := TMessageBodyWriterRegistry.AFFINITY_VERY_LOW;
    end
  );

  // TWiRLValueTypesProvider
  TMessageBodyReaderRegistry.Instance.RegisterReader(
    TWiRLValueTypesProvider,
    function(AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Boolean
    begin
      Result := False;
      case AType.TypeKind of
        tkArray, tkDynArray, tkRecord: Result := True;
      end;
    end,
    function(AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Integer
    begin
      Result := TMessageBodyWriterRegistry.AFFINITY_LOW;
    end
  );

  TMessageBodyWriterRegistry.Instance.RegisterWriter(
    TWiRLValueTypesProvider,
    function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Boolean
    begin
      Result := False;
      case AType.TypeKind of
        tkArray, tkDynArray, tkRecord: Result := True;
      end;
    end,
    function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Integer
    begin
      Result := TMessageBodyWriterRegistry.AFFINITY_VERY_LOW;
    end
  );

  // TWiRLObjectProvider
  TMessageBodyReaderRegistry.Instance.RegisterReader<TObject>(TWiRLObjectProvider, TMessageBodyReaderRegistry.AFFINITY_VERY_LOW);
  TMessageBodyWriterRegistry.Instance.RegisterWriter(
    TWiRLObjectProvider,
    function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Boolean
    begin
      Result := Assigned(AType) and AType.IsInstance;
    end,
    function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: TMediaType): Integer
    begin
      Result := TMessageBodyWriterRegistry.AFFINITY_VERY_LOW;
    end
  );

  // TWiRLJSONValueProvider
  TMessageBodyReaderRegistry.Instance.RegisterReader<TJSONValue>(TWiRLJSONValueProvider);
  TMessageBodyWriterRegistry.Instance.RegisterWriter<TJSONValue>(TWiRLJSONValueProvider);

  // TWiRLStreamProvider
  TMessageBodyReaderRegistry.Instance.RegisterReader<TStream>(TWiRLStreamProvider);
  TMessageBodyWriterRegistry.Instance.RegisterWriter<TStream>(TWiRLStreamProvider, TMessageBodyWriterRegistry.AFFINITY_HIGH);

  {$IFNDEF HAS_NETHTTP_CLIENT}
  TMessageBodyWriterRegistry.Instance.RegisterWriter<TMultipartFormData>(TWiRLMultipartFormDataProvider, TMessageBodyWriterRegistry.AFFINITY_HIGH);
  {$ENDIF}

  // TWiRLStreamingResponse
  TMessageBodyWriterRegistry.Instance.RegisterWriter<TWiRLStreamingResponse>(TWiRLStreamingResponseProvider);

end;

{ TWiRLJSONProvider }

procedure TWiRLJSONProvider.WriteJSONPToStream(AJSON: TJSONValue; AStream: TStream);
var
  LCallback: string;
  LBytes: TBytes;
  LRequest: TWiRLRequest;
begin
  LRequest := FContext.GetContextDataAs<TWiRLRequest>;

  LCallback := LRequest.QueryFields.Values['callback'];
  if LCallback.IsEmpty then
    LCallback := 'callback';

  LBytes := TEncoding.UTF8.GetBytes(LCallback + '(');
  AStream.Write(LBytes[0], Length(LBytes));

  TNeon.PrintToStream(AJSON, AStream, FConfigurationNeon.GetNeonConfig.GetPrettyPrint);

  LBytes := TEncoding.UTF8.GetBytes(');');
  AStream.Write(LBytes[0], Length(LBytes));
end;

procedure TWiRLJSONProvider.WriteJSONToStream(AJSON: TJSONValue; AStream: TStream);
begin
  TNeon.PrintToStream(AJSON, AStream, FConfigurationNeon.GetNeonConfig.GetPrettyPrint);
end;

{ TWiRLMultipartFormDataProvider }

{$IFNDEF HAS_NETHTTP_CLIENT}
procedure TWiRLMultipartFormDataProvider.WriteTo(const AValue: TValue;
  const AAttributes: TAttributeArray; AMediaType: TMediaType;
  AHeaders: IWiRLHeaders; AContentStream: TStream);
var
  LMultipartFormData: TMultipartFormData;
begin
  LMultipartFormData := AValue.AsObject as TMultipartFormData;
  if Assigned(LMultipartFormData) then
  begin
    LMultipartFormData.Stream.Position := 0;
    AContentStream.CopyFrom(LMultipartFormData.Stream, LMultipartFormData.Stream.Size);
  end;
end;
{$ENDIF}

{ TWiRLStreamingResponseProvider }

function TWiRLStreamingResponseProvider.ReadFrom(AType: TRttiType;
  AMediaType: TMediaType; AHeaders: IWiRLHeaders;
  AContentStream: TStream): TValue;
begin
  raise Exception.Create('Not supported');
end;

procedure TWiRLStreamingResponseProvider.WriteTo(const AValue: TValue;
  const AAttributes: TAttributeArray; AMediaType: TMediaType;
  AHeaders: IWiRLHeaders; AContentStream: TStream);
begin
  inherited;
  AValue.AsType<TWiRLStreamingResponse>.SendResponse(FContext);
end;

initialization
  RegisterMessageBodyClasses;

end.

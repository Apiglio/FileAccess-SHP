unit Apiglio_Geo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  MaxPropertyCount = 32;

type

  TAGeoPointRec = record
    x,y,z:double;
  end;

  TAGeoProperty = array[0..MaxPropertyCount-1]of Pointer;
  TAGeoPropertyType = (gptNull=0,gptFixNum=1,gptFloat=2,gptChar=3);//默认是dword、double和{string}pchar
  TAGeoPropertyState = array[0..MaxPropertyCount-1]of record
    PropertyType:TAGeoPropertyType;
    PropertyTitle:string[12];
  end;


  TAGeo = class
  public
    GeoProperty:TAGeoProperty;
  protected
    procedure SetFieldFixNum(field_index:word;value:dword);
    procedure SetFieldFloat(field_index:word;value:double);
    procedure SetFieldChar(field_index:word;value:string);
    function GetFieldFixNum(field_index:word):dword;
    function GetFieldFloat(field_index:word):double;
    function GetFieldChar(field_index:word):string;

  public
    property FixNum[field_index:word]:dword read GetFieldFixNum write SetFieldFixNum;
    property Float[field_index:word]:double read GetFieldFloat write SetFieldFloat;
    property Char[field_index:word]:string read GetFieldChar write SetFieldChar;

  public
    function GetXMin:double;virtual;abstract;
    function GetXMax:double;virtual;abstract;
    function GetYMin:double;virtual;abstract;
    function GetYMax:double;virtual;abstract;
    function GetZMin:double;virtual;abstract;
    function GetZMax:double;virtual;abstract;
  public
    constructor Create;
  end;


  TAGeoPoint = class(TAGeo)
  public
    Point:TAGeoPointRec;
  public
    function GetXMin:double;override;
    function GetXMax:double;override;
    function GetYMin:double;override;
    function GetYMax:double;override;
    function GetZMin:double;override;
    function GetZMax:double;override;
  end;

implementation



function TAGeoPoint.GetXMin:double;
begin
  result:=Self.Point.x;
end;
function TAGeoPoint.GetXMax:double;
begin
  result:=Self.Point.x;
end;
function TAGeoPoint.GetYMin:double;
begin
  result:=Self.Point.y;
end;
function TAGeoPoint.GetYMax:double;
begin
  result:=Self.Point.y;
end;
function TAGeoPoint.GetZMin:double;
begin
  result:=Self.Point.z;
end;
function TAGeoPoint.GetZMax:double;
begin
  result:=Self.Point.z;
end;

procedure TAGeo.SetFieldFixNum(field_index:word;value:dword);
var ptr:pointer;
begin
  assert(field_index<MaxPropertyCount,'超出最大字段数。');
  ptr:=Self.GeoProperty[field_index];
  if ptr<>nil then freemem(ptr,sizeof(ptr));
  ptr:=getmem(sizeof(dword));
  pdword(ptr)^:=value;
  Self.GeoProperty[field_index]:=ptr;
end;
procedure TAGeo.SetFieldFloat(field_index:word;value:double);
var ptr:pointer;
begin
  assert(field_index<MaxPropertyCount,'超出最大字段数。');
  ptr:=Self.GeoProperty[field_index];
  if ptr<>nil then freemem(ptr,sizeof(ptr));
  ptr:=getmem(sizeof(double));
  pdouble(ptr)^:=value;
  Self.GeoProperty[field_index]:=ptr;
end;
procedure TAGeo.SetFieldChar(field_index:word;value:string);
var ptr:pointer;
begin
  assert(field_index<MaxPropertyCount,'超出最大字段数。');
  ptr:=Self.GeoProperty[field_index];
  //if ptr<>nil then freemem(ptr,sizeof(ptr));
  if ptr<>nil then
    begin
      freemem(ptr,StrLen(pchar(ptr))+1);
    end;
  //ptr:=getmem(sizeof(string));
  ptr:=getmem(length(value)+1);
  //pstring(ptr)^:=value;
  StrLCopy(pchar(ptr),@value[1],length(value));
  Self.GeoProperty[field_index]:=ptr;
end;

function TAGeo.GetFieldFixNum(field_index:word):dword;
begin
  result:=pdword(Self.GeoProperty[field_index])^;
end;
function TAGeo.GetFieldFloat(field_index:word):double;
begin
  result:=pdouble(Self.GeoProperty[field_index])^;
end;
function TAGeo.GetFieldChar(field_index:word):string;
begin
  //result:=pstring(Self.GeoProperty[field_index])^;
  result:=pchar(Self.GeoProperty[field_index])^;
end;

constructor TAGeo.Create;
var pi:byte;
begin
  inherited Create;
  for pi:=0 to MaxPropertyCount-1 do GeoProperty[pi]:=nil;
end;

end.


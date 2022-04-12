unit Apiglio_ShapeFile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, Apiglio_Geo;

type

TShapeFileType=(
  shpNull=Longint(0),            //表示这个Shapefile文件不含坐标
  shpPoint=Longint(1),           //表示Shapefile文件记录的是点状目标，但不是多点
  shpPolyLine=Longint(3),        //表示Shapefile文件记录的是线状目标
  shpPolygon=Longint(5),         //表示Shapefile文件记录的是面状目标
  shpMultiPoint=Longint(8),      //表示Shapefile文件记录的是多点，即点集合
  shpPointZ=Longint(11),         //表示Shapefile文件记录的是三维点状目标
  shpPolyLineZ=Longint(13),      //表示Shapefile文件记录的是三维线状目标
  shpPolygonZ=Longint(15),       //表示Shapefile文件记录的是三维面状目标
  shpMultiPointZ=Longint(18),    //表示Shapefile文件记录的是三维点集合目标
  shpPointM=Longint(22),         //表示含有Measure值的点状目标
  shpPolyLineM=Longint(23),      //表示含有Measure值的线状目标
  shpPolygonM=Longint(25),       //表示含有Measure值的面状目标
  shpMultiPointM=Longint(28),    //表示含有Measure值的多点目标
  shpMultiPatch=Longint(31)      //表示复合目标
);

  TAGeoList = specialize TFPGList<TAGeo>;
  TShapeFile = class
  private
    FShpStream:TMemoryStream;//shp文件
    FDbfStream:TMemoryStream;//dbf文件
    FShxStream:TMemoryStream;//shx文件
    FFeature:TAGeoList;//要素列表
    PropertyState:TAGeoPropertyState;//字段列表

  public//临时的public
    FileCode:longint;
    FileLength:longint;
    FileVersion:longint;
    FileType:TShapeFileType;
    Xmin,Xmax,Ymin,Ymax,Zmin,Zmax,Mmin,Mmax:double;

  Private
    procedure FeatureToShp;
    procedure ShpToFeature;
  public
    procedure LoadFromFile(filename:string);
    procedure SaveToFile(filename:string);
  public
    procedure AddFeature(fea:TAGeo);
    function AddField(field_name:string;field_type:TAGeoPropertyType):word;//返回新建字段的序号，如果失败返回0（Id的序号）

  public
    procedure SaveAsJSON(filename:string);
    procedure SaveAsCSV(filename:string);
    procedure SaveAsKML(filename:string);
    procedure SaveAsSVG(filename:string);
    function ConvertToRubyHash:string;
    function ConvertToPythonDictionary:string;

  protected
    constructor Create;
  public
    constructor Create(filename:string);//根据已有文件创建链接
    constructor Create(ShpType:TShapeFileType);//根据特定类型创建空文件
    destructor Destroy;override;
  end;

var
  DE_GPT_CHAR:string;
  DE_GPT_FLOAT:double;
  DE_GPT_FIXNUM:dword;

implementation

function ShpTypeToFeatureClass(ShpType:TShapeFileType):TClass;
begin
  result:=TObject;
  case ShpType of
    //shpNull:;
    shpPoint:result:=TAGeoPoint;
    //shpPolyLine:;
    //shpPolygon:;
    //shpMultiPoint:;
    //shpPointZ:;
    //shpPolyLineZ:;
    //shpPolygonZ:;
    //shpMultiPointZ:;
    //shpPointM:;
    //shpPolyLineM:;
    //shpPolygonM:;
    //shpMultiPointM:;
    //shpMultiPatch:;
    else Assert(false,'无效的shp类型。')
  end;
end;

function TypeSize(t:TAGeoPropertyType):byte;
begin
  case t of
    gptNull:result:=0;
    gptFixNum:result:=9;
    gptFloat:result:=19;
    gptChar:result:=50;
    else Assert(false,'错误的TAGeoPropertyType类型。');
  end;
end;
function RecSize(r:TAGeoPropertyState):word;
var pi:integer;
begin
  result:=7;//记录第一个字符一定是空格，Id长度为6
  for pi:=1 to MaxPropertyCount-1 do
    inc(result,TypeSize(r[pi].PropertyType));
end;
{
function EndianReverse(num:qword):qword;overload;
var i:byte;
begin
  result:=qword(0);
  for i:=1 to 8-1 do
    begin
      result:=result + num mod 256;
      num:=num shr 8;
      result:=result shl 8;
    end;
  result:=result+num;
end;
function EndianReverse(num:dword):dword;overload;
var i:byte;
begin
  result:=dword(0);
  for i:=1 to 4-1 do
    begin
      result:=result + num mod 256;
      num:=num shr 8;
      result:=result shl 8;
    end;
  result:=result+num;
end;
function EndianReverse(num:word):word;overload;
var i:byte;
begin
  result:=word(0);
  for i:=1 to 2-1 do
    begin
      result:=result + num mod 256;
      num:=num shr 8;
      result:=result shl 8;
    end;
  result:=result+num;
end;
}



procedure TShapeFile.FeatureToShp;
var fid:longint;
    ptr:pointer;
    field:0..MaxPropertyCount-1;
    pos:int64;
    stmp:string;
begin

  FShpStream.Clear;FShpStream.SetSize(100);FShpStream.Position:=0;
  FShpStream.WriteDWord(SwapEndian(dword(9994)));FShpStream.WriteDWord(0);
  FShpStream.WriteDWord(0);FShpStream.WriteDWord(0);FShpStream.WriteDWord(0);
  FShpStream.WriteDWord(0);FShpStream.WriteDWord(SwapEndian(dword(Self.FileLength)));
  FShpStream.WriteDWord(Self.FileVersion);FShpStream.WriteDWord(dword(Self.FileType));
  FShpStream.WriteQWord(qword(Self.Xmin));FShpStream.WriteQWord(qword(Self.Ymin));
  FShpStream.WriteQWord(qword(Self.Xmax));FShpStream.WriteQWord(qword(Self.Ymax));
  FShpStream.WriteQWord(0);FShpStream.WriteQWord(0);
  FShpStream.WriteQWord(0);FShpStream.WriteQWord(0);

  FShxStream.Clear;FShxStream.SetSize(100);FShxStream.Position:=0;
  FShxStream.WriteDWord(SwapEndian(dword(9994)));FShxStream.WriteDWord(0);
  FShxStream.WriteDWord(0);FShxStream.WriteDWord(0);FShxStream.WriteDWord(0);
  FShxStream.WriteDWord(0);FShxStream.WriteDWord(SwapEndian(dword(Self.FileLength)));
  FShxStream.WriteDWord(Self.FileVersion);FShxStream.WriteDWord(dword(Self.FileType));
  FShxStream.WriteQWord(qword(Self.Xmin));FShxStream.WriteQWord(qword(Self.Ymin));
  FShxStream.WriteQWord(qword(Self.Xmax));FShxStream.WriteQWord(qword(Self.Ymax));
  FShxStream.WriteQWord(0);FShxStream.WriteQWord(0);
  FShxStream.WriteQWord(0);FShxStream.WriteQWord(0);

  FDbfStream.Clear;
  FDbfStream.SetSize(32);
  FDbfStream.Position:=0;
  FDbfStream.WriteDWord($18077203);
  FDbfStream.WriteDWord(Self.FFeature.Count);
  FDbfStream.WriteWord($0000);//瞎写一个先
  FDbfStream.WriteWord(RecSize(Self.PropertyState));
  FDbfStream.WriteQWord(0);FDbfStream.WriteQWord(0);
  FDbfStream.WriteDWord($00004D00);//选择中文
  field:=0;
  while (PropertyState[field].PropertyType<>gptNull) and (field<MaxPropertyCount) do
    begin
      FDbfStream.WriteBuffer((PropertyState[field].PropertyTitle[1]),11);
      case PropertyState[field].PropertyType of
        gptFixNum:
          begin
            FDbfStream.WriteByte(ord('N'));
            FDbfStream.WriteDWord(0);
            if PropertyState[field].PropertyTitle='Id' then FDbfStream.WriteWord($0006) else FDbfStream.WriteWord($0009);;
          end;
        gptFloat:
          begin
            FDbfStream.WriteByte(ord('F'));
            FDbfStream.WriteDWord(0);
            FDbfStream.WriteWord($0B13);
          end;
        gptChar:
          begin
            FDbfStream.WriteByte(ord('C'));
            FDbfStream.WriteDWord(0);
            FDbfStream.WriteWord($0032);
          end;
      end;
      FDbfStream.WriteWord(0);
      FDbfStream.WriteDWord(0);
      FDbfStream.WriteQWord(0);
      inc(field);
    end;
  FDbfStream.WriteByte($0D);
  pos:=FDbfStream.Position;
  FDbfStream.Position:=8;
  FDbfStream.WriteWord(pos);
  FDbfStream.Position:=pos;

  for fid:=0 to FFeature.Count-1 do
    begin
      field:=0;
      FDbfStream.WriteByte($20);
      while (PropertyState[field].PropertyType<>gptNull) and (field<MaxPropertyCount) do
        begin
          case PropertyState[field].PropertyType of
            gptFixNum:
              begin
                ptr:=FFeature.Items[fid].GeoProperty[field];
                if ptr=nil then ptr:=@DE_GPT_FIXNUM;
                stmp:=IntToStr(pdword(ptr)^);
                if PropertyState[field].PropertyTitle='Id' then begin
                  if length(stmp)>6 then stmp:='000000' else while length(stmp)<6 do stmp:=' '+stmp;
                  FDbfStream.WriteBuffer(stmp[1],6);
                end else begin
                  if length(stmp)>9 then stmp:='000000000' else while length(stmp)<9 do stmp:=' '+stmp;
                  FDbfStream.WriteBuffer(stmp[1],9);
                end;
              end;
            gptFloat:
              begin
                ptr:=FFeature.Items[fid].GeoProperty[field];
                if ptr=nil then ptr:=@DE_GPT_FLOAT;
                stmp:=FloatToStrF(pdouble(ptr)^,ffExponent,12,3);
                //if length(stmp)>19 then stmp:=' 0.00000000000e+000' else while length(stmp)<19 do stmp:=' '+stmp;
                while length(stmp)<19 do stmp:=' '+stmp;
                FDbfStream.WriteBuffer(stmp[1],19);
              end;
            gptChar:
              begin
                ptr:=FFeature.Items[fid].GeoProperty[field];

                //if ptr=nil then ptr:=@DE_GPT_CHAR;
                if ptr=nil then ptr:=@(DE_GPT_CHAR[1]);
                //stmp:=pstring(ptr)^;
                stmp:=pchar(ptr);

                if length(stmp)>50 then
                  stmp:=DE_GPT_CHAR else
                while length(stmp)<50 do stmp:=stmp+' ';
                FDbfStream.WriteBuffer(stmp[1],50);
              end;
          end;
          inc(field);
        end;
    end;

  FDbfStream.WriteByte($1A);//结尾

  case Self.FileType of
    shpPoint:
      begin
        for fid:=0 to FFeature.Count-1 do
          begin
            FShxStream.WriteDWord(SwapEndian(dword(FShpStream.Position div 2)));
            FShxStream.WriteDWord(SwapEndian(dword(10)));//单点格式长度固定

            FShpStream.WriteDWord(SwapEndian(dword(fid+1)));
            FShpStream.WriteQWord($000000010A000000);
            FShpStream.WriteQWord(QWord((FFeature.Items[fid] as TAGeoPoint).Point.x));
            FShpStream.WriteQWord(QWord((FFeature.Items[fid] as TAGeoPoint).Point.y));
          end;
      end
    else ;
  end;
  pos:=FShpStream.Position;
  FShpStream.Position:=24;
  FShpStream.WriteDWord(SwapEndian(dword(pos div 2)));

  pos:=FShxStream.Position;
  FShxStream.Position:=24;
  FShxStream.WriteDWord(SwapEndian(dword(pos div 2)));


end;
procedure TShapeFile.ShpToFeature;
begin

end;

procedure TShapeFile.LoadFromFile(filename:string);
begin

end;
procedure TShapeFile.SaveToFile(filename:string);
begin
  FeatureToShp;
  FShpStream.SaveToFile(filename+'.shp');
  FDbfStream.SaveToFile(filename+'.dbf');
  FShxStream.SaveToFile(filename+'.shx');
end;

procedure TShapeFile.AddFeature(fea:TAGeo);
var tmp:double;
begin
  Assert(fea is ShpTypeToFeatureClass(Self.FileType),'不能添加不符合shp类型的对象');
  FFeature.Add(fea);

  tmp:=fea.GetXMax;
  if tmp>Self.Xmax then Self.Xmax:=tmp;
  tmp:=fea.GetXMin;
  if tmp<Self.Xmin then Self.Xmin:=tmp;
  
  tmp:=fea.GetYMax;
  if tmp>Self.Ymax then Self.Ymax:=tmp;
  tmp:=fea.GetYMin;
  if tmp<Self.Ymin then Self.Ymin:=tmp;

  tmp:=fea.GetZMax;
  if tmp>Self.Zmax then Self.Zmax:=tmp;
  tmp:=fea.GetZMin;
  if tmp<Self.Zmin then Self.Zmin:=tmp;

  inc(FileLength);
end;

function TShapeFile.AddField(field_name:string;field_type:TAGeoPropertyType):word;
var pi:word;
begin
  pi:=1;
  while (PropertyState[pi].PropertyType<>gptNull) and (pi<MaxPropertyCount) and (pi<>0) do inc(pi);
  if (pi<>0) and (pi<MaxPropertyCount) then
    begin
      PropertyState[pi].PropertyType:=field_type;
      PropertyState[pi].PropertyTitle:=field_name;
      result:=pi;
    end
  else result:=0;
end;

procedure TShapeFile.SaveAsJSON(filename:string);
begin

end;
procedure TShapeFile.SaveAsCSV(filename:string);
begin

end;
procedure TShapeFile.SaveAsKML(filename:string);
begin

end;
procedure TShapeFile.SaveAsSVG(filename:string);
begin

end;
function TShapeFile.ConvertToRubyHash:string;
begin

end;
function TShapeFile.ConvertToPythonDictionary:string;
begin

end;

constructor TShapeFile.Create(filename:string);
begin
  Create;
  LoadfromFile(filename);
end;
constructor TShapeFile.Create(ShpType:TShapeFileType);
begin
  Create;
  Self.FileCode:=9994;
  Self.FileType:=ShpType;
  Self.FileLength:=0;
  Self.FileVersion:=1000;
  Self.Xmin:=0;
  Self.Ymin:=0;
  Self.Xmax:=0;
  Self.Ymax:=0;
  Self.Zmin:=0;
  Self.Zmax:=0;
  Self.Mmin:=0;
  Self.Mmax:=0;
end;
constructor TShapeFile.Create;
var pi:integer;
begin
  inherited Create;
  FShpStream:=TMemoryStream.Create;
  FDbfStream:=TMemoryStream.Create;
  FShxStream:=TMemoryStream.Create;
  FFeature:=TAGeoList.Create;
  with PropertyState[0] do
    begin
      PropertyTitle:='Id';
      PropertyType:=gptFixNum;
    end;
  for pi:=1 to MaxPropertyCount-1 do PropertyState[pi].PropertyType:=gptNull;
end;
destructor TShapeFile.Destroy;
begin
  FShpStream.Free;
  FDbfStream.Free;
  FShxStream.Free;
  FFeature.Free;
  inherited Destroy;
end;


initialization

  DE_GPT_CHAR:=#32+#32+#32+#32+#32+#32+#32+#32+#32+#32
              +#32+#32+#32+#32+#32+#32+#32+#32+#32+#32
              +#32+#32+#32+#32+#32+#32+#32+#32+#32+#32
              +#32+#32+#32+#32+#32+#32+#32+#32+#32+#32
              +#32+#32+#32+#32+#32+#32+#32+#32+#32+#32;
  DE_GPT_FLOAT:=2.20488625154985E-314;
  DE_GPT_FIXNUM:=0;

end.


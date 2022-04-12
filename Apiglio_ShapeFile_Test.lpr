program Apiglio_ShapeFile_Test;

uses Apiglio_ShapeFile, Apiglio_Geo, Classes, Sysutils;

var mySHP:TShapeFile;
    tmp:TAGeoPoint;

begin

  mySHP:=TShapeFile.Create(shpPoint);
  mySHP.AddField('name',gptChar);
  mySHP.AddField('float',gptFloat);
  mySHP.AddField('num',gptFixNum);

  tmp:=TAGeoPoint.Create;
  tmp.Point.x:=0;
  tmp.Point.y:=0;

  tmp.Char[1]:='AAAAA';
  tmp.Float[2]:=12.99832;
  tmp.FixNum[3]:=223466;

  mySHP.AddFeature(tmp);
  tmp:=TAGeoPoint.Create;
  tmp.Point.x:=100;
  tmp.Point.y:=100;

  tmp.Char[1]:='deddde';
  tmp.Float[2]:=-1332.932;
  tmp.FixNum[3]:=304066;

  mySHP.AddFeature(tmp);
  tmp:=TAGeoPoint.Create;
  tmp.Point.x:=300;
  tmp.Point.y:=500;

  tmp.Char[1]:=utf8toansi('中文测试');
  tmp.Float[2]:=0.00232;
  tmp.FixNum[3]:=22340;

  mySHP.AddFeature(tmp);
  mySHP.SaveToFile('test');


  writeln(FloatToStrF(3.9937423e-007,ffExponent,12,3));

  readln;

end.


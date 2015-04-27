import "dart:async";

import "package:locking/locking.dart";
import "package:unittest/unittest.dart";

var _obj = new Object();

Future webRequest() {
  Completer completer = new Completer();
  Duration duration = new Duration(milliseconds: 100);
  Timer timer = new Timer(duration, () => completer.complete() );
  return completer.future;
}

Future waitUntil( bool func( ) )
{
  var completer = new Completer( );

  new Timer.periodic( const Duration( milliseconds: 10 ), ( Timer timer ) {
    if ( func( ) ) {
      completer.complete( );
      timer.cancel( );
    }
  } );

  return completer.future;
}

Future main() async {
  test( "Does not run code in lock more than once at same time", () async {
    int timesRun = 0;
    var result = [];
    var lockObj = new Object();

    Future addEvent( int id ) async {
      if(!result.contains(id)){
        await lock(lockObj, () async {
          if(!result.contains(id)){
            await webRequest();
            result.add( id );
          }
        });
      }
      timesRun++;
    }

    for(var timesRun = 0; timesRun < 10; timesRun++){
      for(var id = 0; id < 5;id++){
        addEvent(id);
      }
    }

    await waitUntil( () => timesRun == 50);

    expect(result.length, 5);
  } );

  await runZoned(() async {
    await lock(_obj, () async {
      try {
        print("x1");
        await install();
        print("x2");
      } finally {
        print("x3");
      }
    });
  });

  await runZoned(() async {
    await lock(_obj, () async {
      try {
        print("z1");
        await install();
        print("z2");
      } finally {
        print("z3");
      }
    });
  });
}

Future install() async {
  try {
    await new Future(() {
      print("y1");
    });
  } finally {
    print("y2");
  }
}

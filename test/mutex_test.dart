import "dart:async";

import "package:locking/locking.dart";
import "package:test/test.dart";

/// Account simulating the classic "simultaneous update" concurrency problem.
///
class Account {
  int get balance => _balance;
  int _balance = 0;

  Mutex mutex;

  /// Set to true to print out read/write to the balance during deposits
  static final bool debugOutput = false;

  DateTime _startTime;

  void _debugPrint([String message]) {
    if (debugOutput) {
      if (message != null) {
        var t = new DateTime.now().difference(_startTime).inMilliseconds;
        print("$t: $message");
      } else {
        print("");
      }
    }
  }

  /// Constructor for an account.
  ///
  /// Uses RentrantMutex if [reentrant] is true; otherwise uses NormalMutex.
  ///
  Account({bool reentrant: true}) {
    mutex = (reentrant) ? new ReentrantMutex() : new NormalMutex();
    _startTime = new DateTime.now();
  }

  void reset([int startingBalance = 0]) {
    _balance = startingBalance;
    if (debugOutput) {
      _startTime = new DateTime.now();
      _debugPrint();
    }
  }

  /// Waits [startDelay] and then invokes critical section without mutex.
  ///
  Future depositUnsafe(int amount, int startDelay, int dangerWindow) async {
    await sleep(new Duration(milliseconds: startDelay));
    await _criticalSection(amount, dangerWindow);
  }

  /// Waits [startDelay] and then invokes critical section with mutex.
  ///
  Future depositWithMutex(int amount, int startDelay, int dangerWindow) async {
    await sleep(new Duration(milliseconds: startDelay));
    await mutex.acquire();
    try {
      await _criticalSection(amount, dangerWindow);
    } finally {
      mutex.release();
    }
  }

  /// Critical section of adding [amount] to the balance.
  ///
  /// Reads the balance, then sleeps for [dangerWindow] milliseconds, before
  /// saving the new balance. If not protected, another invocation of this
  /// method while it is sleeping will read the balance before it is updated.
  /// The one that saves its balance last will overwrite the earlier saved
  /// balances (effectively those other deposits will be lost).
  ///
  Future _criticalSection(int amount, int dangerWindow) async {
    _debugPrint("read $_balance");

    var tmp = _balance;
    await sleep(new Duration(milliseconds: dangerWindow));
    _balance = tmp + amount;

    _debugPrint("write $_balance (= $tmp + $amount)");
  }
}

//----------------------------------------------------------------

Future main() async {
  final int CORRECT_BALANCE = 68;

  group("normal mutex", () {
    var account = new Account(reentrant: false);

    test("acquire/release in same zone", () async {
      // First demonstrate that without mutex incorrect results are produced.

      // Without mutex produces incorrect result
      // 000. a reads 0
      // 025. b reads 0
      // 050. a writes 42
      // 075. b writes 26
      account.reset();
      await Future.wait([
        account.depositUnsafe(42, 0, 50),
        account.depositUnsafe(26, 25, 50) // result overwrites first deposit
      ]);
      expect(account.balance, equals(26)); // incorrect: first deposit lost

      // Without mutex produces incorrect result
      // 000. b reads 0
      // 025. a reads 0
      // 050. b writes 26
      // 075. a writes 42
      account.reset();
      await Future.wait([
        account.depositUnsafe(42, 25, 50), // result overwrites second deposit
        account.depositUnsafe(26, 0, 50)
      ]);
      expect(account.balance, equals(42)); // incorrect: second deposit lost

      // Test correct results are produced with mutex

      // With mutex produces correct result
      // 000. a acquires lock
      // 000. a reads 0
      // 025. b is blocked
      // 050. a writes 42
      // 050. a releases lock
      // 050. b acquires lock
      // 050. b reads 42
      // 100. b writes 68
      account.reset();
      await Future.wait([
        account.depositWithMutex(42, 0, 50),
        account.depositWithMutex(26, 25, 50)
      ]);
      expect(account.balance, equals(CORRECT_BALANCE));

      // With mutex produces correct result
      // 000. b acquires lock
      // 000. b reads 0
      // 025. a is blocked
      // 050. b writes 26
      // 050. b releases lock
      // 050. a acquires lock
      // 050. a reads 26
      // 100. a writes 68
      account.reset();
      await Future.wait([
        account.depositWithMutex(42, 25, 50),
        account.depositWithMutex(26, 0, 50)
      ]);
      expect(account.balance, equals(CORRECT_BALANCE));
    });

    test("acquire/release in different zones", () async {
      account.reset();
      await Future.wait([
        account.depositWithMutex(42, 0, 50),
        runZoned(() => account.depositWithMutex(26, 25, 50))
      ]);
      expect(account.balance, equals(CORRECT_BALANCE));

      account.reset();
      await Future.wait([
        account.depositWithMutex(42, 25, 50),
        runZoned(() => account.depositWithMutex(26, 0, 50))
      ]);
      expect(account.balance, equals(CORRECT_BALANCE));
    });
  });

  group("reentrant mutex", () {
    // Test basic acquire/release with a NormalMutex (as well as what happens
    // if no mutex is used).

    var reentAcc = new Account(reentrant: true);

    test("acquire/release in same zone", () async {
      // Since these mutex are acquired in the same zone, they acquire without
      // blocking, so do not produce the desired protection.

      reentAcc.reset();
      await Future.wait([
        reentAcc.depositWithMutex(42, 0, 50),
        reentAcc.depositWithMutex(26, 25, 50)
      ]);
      expect(reentAcc.balance, equals(26)); // incorrect balance

      reentAcc.reset();
      await Future.wait([
        reentAcc.depositWithMutex(42, 25, 50),
        reentAcc.depositWithMutex(26, 0, 50)
      ]);
      expect(reentAcc.balance, equals(42)); // incorrect balance
    });

    test("acquire/release in different zones", () async {
      // Reentrant mutex acquired in different zones produce desired protection.

      reentAcc.reset();
      await Future.wait([
        reentAcc.depositWithMutex(42, 0, 50),
        runZoned(() => reentAcc.depositWithMutex(26, 25, 50))
      ]);
      expect(reentAcc.balance, equals(CORRECT_BALANCE));

      reentAcc.reset();
      await Future.wait([
        reentAcc.depositWithMutex(42, 25, 50),
        runZoned(() => reentAcc.depositWithMutex(26, 0, 50))
      ]);
      expect(reentAcc.balance, equals(CORRECT_BALANCE));
    });
  });
}

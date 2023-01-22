import 'dart:async';
import 'package:conduit_core/conduit_core.dart';   

class Migration4 extends Migration { 
  @override
  Future upgrade() async {
   		database.deleteColumn("_User", "password");
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    
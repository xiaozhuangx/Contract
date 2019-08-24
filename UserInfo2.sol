pragma solidity ^0.4.24;

import "./Table.sol";

contract UserInfo2{

   //监控事件
   event CreateResult(int count);
   event InsertResult(int count);
   event UserInfo(string username, string name, string identity, string agency);
    
   // 创建表
   function create() public returns(int){
      TableFactory tf = TableFactory(0x1001);  // TableFactory的地址固定为0x1001
      int count = tf.createTable("t_user_info1", "username", "name, identity, agency");
      emit CreateResult(count);
        
      return count;
    }
   

   // 创建用户身份
   function user_create(
      string username,     //用户名
      string name,         //姓名
      string identity,     //身份证
      string agency        //授权机构
   )
      public
      returns(int)
   {
      TableFactory tf = TableFactory(0x1001);
      Table table = tf.openTable("t_user_info1");
      // 检查是否存在编号相同
      Condition condition = table.newCondition();
      Entries entries = table.select(username, condition);

      Entry entry = table.newEntry();
      entry.set("username", username);
      entry.set("name", name);
      entry.set("identity", identity);
      entry.set("agency", agency);

      int count = table.insert(username, entry);

      emit UserInfo(username, name, identity, agency);

      return count;
   }

   // 读取 用户身份 信息
   function user_get(
      string username
   )
      public
      view
      returns(string, string ,string, string)
   {
      TableFactory tf = TableFactory(0x1001);
      Table table = tf.openTable("t_user_info1");
      // 检查是否存在编号相同
      Condition condition = table.newCondition();
      Entries entries = table.select(username, condition);

      Entry entry = entries.get(0);
      string memory _username = entry.getString("username");
      string memory _name = entry.getString("name");
      string memory _identity = entry.getString("identity");
      string memory _agency = entry.getString("agency");

      return (_username, _name, _identity, _agency);
   }
}

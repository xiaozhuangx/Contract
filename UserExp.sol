pragma solidity ^0.4.24;



import "./Table.sol";



contract UserExp{
    
    //监控事件
    event CreateResult(int count);

    event RegisterEvent(int ret_code, string username, uint exp);

    event UpdateExp(string username, uint exp);



    function create() public returns(int) {

        TableFactory tf = TableFactory(0x1001);

        // 积分管理表, key : username, field : user_exp

        // |    用户名(主键)     |     用户积分      |

        // |-------------------- |-------------------|

        // |        username     |    user_exp       |     

        // |---------------------|-------------------|

        //

        // 创建表

        int count = tf.createTable("t_user_exp", "username", "user_exp");

        emit CreateResult(count);

        return count;

    }

    

    function openTable() private returns(Table) {

        TableFactory tf = TableFactory(0x1001);

        Table table = tf.openTable("t_user_exp");

        return table;

    }

    

    /*

    描述 : 根据用户名查询用户积分(实现全平台通用积分系统，后续可设置积分兑换机制)

    参数 ： 

            username : 用户名



    返回值：

            参数一： 成功返回0, 用户名不存在返回-1

            参数二： 第一个参数为0时有效，积分数

    */

    function select(string username) public constant returns(int256, uint256) {

        // 打开表

        Table table = openTable();

        // 查询

        Entries entries = table.select(username, table.newCondition());

        uint256 user_exp = 0;

        if (0 == uint256(entries.size())) {

            return (-1, user_exp);

        } else {

            Entry entry = entries.get(0);

            return (0, uint256(entry.getInt("user_exp")));

        }

    }

    

    /*

    描述 : 积分初始化

    参数 ： 

            username  : 用户名

            user_exp  : 用户积分

    返回值：

            0  初始化成功

            -1 用户名已存在

            -2 其他错误

    */

    function set_user_exp(string username, uint256 user_exp) public returns(int256){

        int256 ret_code;

        int256 ret= 0;

        uint256 temp_user_exp = 0;

        // 查询用户名是否存在

        (ret, temp_user_exp) = select(username);

        if(ret != 0) {

            Table table = openTable();

            

            Entry entry = table.newEntry();

            entry.set("username", username);

            entry.set("user_exp", int256(user_exp));

            // 插入

            int count = table.insert(username, entry);

            if (count == 1) {

                // 成功

                ret_code = 0;

            } else {

                // 失败? 无权限或者其他错误

                ret_code = -2;

            }

        } else {

            // 用户名已存在

            ret_code = -1;

        }

        emit RegisterEvent(ret_code, username, user_exp);

        return ret_code;

    }

    

    //更新积分

    function update_exp(string username, uint256 exp) public{

        uint256 pre_exp = 0;

        int256 ret = 0;

        (ret, pre_exp) = select(username);

        Table table = openTable();

        Entry entry = table.newEntry();

        entry.set("username", username);

        entry.set("user_exp", int256(pre_exp + exp));

        //更新用户积分

        table.update(username, entry, table.newCondition());

        emit UpdateExp(username, exp);

    }

}





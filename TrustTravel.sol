pragma solidity ^0.4.24;

contract TrustTravel {

    //景点信息
    struct SceneInfo{
        string province;              //省
        string city;                   //市
        string S_name;                //景点名字
        uint S_price;                 //门票
    }
    
    // 酒店房间
    struct Room {
        string detailAddr;
        string hotel;                // 酒店名
        string roomType;             // 房间类型
        string fromDate;             // 入住日期 2018-11-3
        string toDate;               // 离开日期 2018-11-5
        uint totalPrice;             // 总价格     
    }
    
    // 评论信息
    struct Comment {
        uint time;                   //评论时间
        string content;              //评语
        uint score;                  //评分
        bool exist;                  // 判断是否存在
        string hash;                 // 交易hash
    }

    // 用户预订旅游门票
    struct UserSceneOrder {
        uint time;                  //时间戳
        SceneInfo sceneInfo;        //预定景点信息
        string OTA;                 //预定的平台
        string state;               //订单状态
        uint flag1;                 //设置整型，定义交易状态
        Comment comment;            // 评论
        string hash;                // 交易hash
    }

    // 用户酒店交易
    struct UserOrder {
        uint time;                  // 时间戳 unix
        Room room;                  // 订购房间
        //SceneInfo sceneInfo;      //预定景点信息
        string OTA;                 // 订购的平台
        string state;               // 表明订单状态：init/confirmed
        uint flag;                  //设置整型，定义交易状态
        Comment comment;            // 评论
        string hash;                // 交易hash
    }


    //用户列表下的信息
    struct User {
        string userName;
        //uint passwd;
        uint Owner_money;
        UserOrder[] orders;
        UserSceneOrder[] orders1;
    }
    
    //用户登陆注册
    struct UserInfo {
        string passwd;
        address addr;
    }
    

    //mapping (address => Comment) public commentInfo;
    mapping (address => User) public userInfo;

    // 存储账户类型
    mapping (address => string) public accountType; 

    // 用户名对应用户的信息
    mapping (string => UserInfo) Login;


    constructor() public  { 

    }

    //监控用户
    event Users(string username, address addr);

    //事件监控
    event BookingHotel(address _addr, string _detailaddr, string hotel, uint price);
    event BookingScene(address _addr, string s_name, uint price);
    event CommentsInfo(address _addr, uint _idx, string content, uint score);

    /*
    描述: 用户注册，判断用户是否首次注册，是则进行注册并初始化用户金额。
    */
    function UserRegister(string memory username, string passwd, address _addr) public returns(bool, string memory, string memory){
        require(
            Login[username].addr == address(0)
        );
        Login[username].passwd = passwd;
        Login[username].addr = _addr;
        setUserMoney(_addr);
        emit Users(username, _addr);
        return(true, username, "Register successful!");
    }

    // solidity比较字符串方式
    function compareStringsbyBytes(string memory s1, string memory s2) public pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
    
    /*
    描述：用户登陆。
    参数：
            username        :        用户名
            passwd         ：       用户名对应的密码
    返回值：

            bool            :        登陆成功或者失败
            address         :        成功返回用户地址，失败则返回假地址(预设)
    */
    function UserLogin(string memory username, string passwd) view public returns(bool, string memory, address){
        if (compareStringsbyBytes(Login[username].passwd,passwd)) {
            return(true, "Login successful", Login[username].addr);
        }else{
            //假设这是一个假的地址.
            return(false, "Login fail", 0x79a7A47806D2dfee07b42662C4F65816461d14d2);
        }
    }
    
    //获取用户地址
    function GetUserAddress(string memory username) view public returns(address) {
        return Login[username].addr;
    }

    //初始化用户的余额
    function setUserMoney(address _addr) private{
        //管理者给每个初始用户10000的金额作为本金
        userInfo[_addr].Owner_money = 10000;
    }


    //预定景点门票(用户通过自己的地址进行订购)
    function bookOrder(address _addr, string memory _province, string memory _city, string memory s_name, uint s_price, string memory _OTA, uint f1) public {
        //require(passwd == userInfo[_addr].passwd && username == userInfo[_addr].username);
        SceneInfo memory sceneInfo = SceneInfo(_province, _city, s_name, s_price);
        Comment memory comment = Comment(0, "", 5, false, "");

        UserSceneOrder memory userSceneOrder = UserSceneOrder(now, sceneInfo, _OTA, "initialization", f1, comment, "");
        userInfo[_addr].orders1.push(userSceneOrder);
        userInfo[_addr].Owner_money -= s_price;

        emit BookingScene(_addr, s_name, s_price);
    }

    // 订购酒店房间
    function initializeOrder(address _addr, string memory _detailaddr, string memory _hotel, string memory _roomType, string memory _fromDate, string memory _toDate, string memory _OTA, uint _totalPrice, uint f2) public {
        //require(passwd == userInfo[_addr].passwd && username == userInfo[_addr].username);
        Room memory room = Room(_detailaddr, _hotel, _roomType, _fromDate, _toDate, _totalPrice);
        Comment memory comment = Comment(0, "", 5, false, "");
        //SceneInfo memory sceneInfo = SceneInfo(_province, _city, s_name, s_price);
        UserOrder memory userOrder = UserOrder(now, room, _OTA, "initialization", f2, comment, "");
        userInfo[_addr].orders.push(userOrder);

        userInfo[_addr].Owner_money -= _totalPrice;

        emit BookingHotel(_addr, _detailaddr, _hotel, _totalPrice);
    }
    
    /*
    描述：对酒店订单进行评价， 当且仅当用户订购酒店成功以后才可以进行评论。
    */
    function addCommentForHotel(uint _idx, address _addr, string memory content, uint score) public {
        require(
            userInfo[_addr].orders[_idx].flag == 1
        );
        Comment memory comment = Comment(now, content, score, true, "");
        userInfo[_addr].orders[_idx].comment = comment;

        emit CommentsInfo(_addr, _idx, content, score);
    }

    
    //对景点订单进行评价，当且仅当用户订购景点门票成功以后才可以进行评论。
    function addCommentForScene(uint _idx, address _addr, string memory content, uint score) public{
        require(
            userInfo[_addr].orders1[_idx].flag1 == 1
        );
        Comment memory comment = Comment(now, content, score, true, "");
        userInfo[_addr].orders1[_idx].comment = comment;

        emit CommentsInfo(_addr, _idx, content, score);
    }   

    
    // solidity 不能返回结构体，更不能返回结构体数组...
    // 所以这里的操作有点麻烦
    // 得到用户订单的附加信息 用户订单分为info(userOrder结构体里的其他信息)和room
    function getUserOrdersInfo(uint _idx, address _addr) public view returns (uint, string memory, string memory, string memory){
       uint _time =  userInfo[ _addr].orders[_idx].time;
       string storage _OTA = userInfo[ _addr].orders[_idx].OTA;
       string storage _state = userInfo[ _addr].orders[_idx].state;
        string storage _hash = userInfo[ _addr].orders[_idx].hash;

       return (_time, _OTA, _state, _hash);
    }
    
    /*
    描述：获取用户订单的附加信息-景点
    参数：
            _addr          :          用户地址
            _idx           :          订单编号
    返回值:
            _time          :         订购时间
            _OTA           :         订购平台 
            _state         ：         订购状态
            _hash          :         订单hash
    */
    function getUserSceneOrdersInfo(uint _idx, address _addr) public view returns(uint, string memory, string memory, string memory){
        uint _time =  userInfo[ _addr].orders1[_idx].time;
        string storage _OTA = userInfo[ _addr].orders1[_idx].OTA;
        string storage _state = userInfo[ _addr].orders1[_idx].state;
        string storage _hash = userInfo[ _addr].orders1[_idx].hash;
        return (_time, _OTA, _state, _hash);
    }

    /*
    描述：得到用户订单的酒店信息
    参数：
            _addr          :          用户地址
            _idx           :          订单编号
    返回值：
            _hotel          :          酒店名
            _roomType      ：         房间类型
            _fromDate      ：         入住时间
            _toDate        ：         离店时间
            _totalPrice    ：         房间价格
            _detailAddr    ：         酒店详细地址
    */
    function getUserOrdersRoom(uint _idx, address _addr) public view returns (string memory, string memory, string memory, string memory, uint, string memory){
        string storage _hotel = userInfo[_addr].orders[_idx].room.hotel;
        string storage _roomType = userInfo[_addr].orders[_idx].room.roomType;
        string storage _fromDate = userInfo[_addr].orders[_idx].room.fromDate;
        string storage _toDate = userInfo[_addr].orders[_idx].room.toDate;
        uint _totalPrice = userInfo[_addr].orders[_idx].room.totalPrice;
        string storage _detailAddr = userInfo[_addr].orders[_idx].room.detailAddr;

        return (_hotel, _roomType, _fromDate, _toDate, _totalPrice, _detailAddr);
    }
    
    //得到用户订单的景点信息
    function getUserOtherScene(uint _idx, address _addr) public view returns (string memory, string memory, string memory, uint){
        string storage _province = userInfo[_addr].orders1[_idx].sceneInfo.province;
        string storage _city = userInfo[_addr].orders1[_idx].sceneInfo.city;
        string storage _name = userInfo[_addr].orders1[_idx].sceneInfo.S_name;
        uint _price = userInfo[_addr].orders1[_idx].sceneInfo.S_price;
        return(_province, _city, _name, _price);
    }

    /*
    描述：获得酒店评论
    参数： 
            _addr             :        用户地址
            _idx              :        订单编号
    返回值：
            _content          :        评价内容
            _hash             :        评论订单hash值
            _score            :        评分
            _commentTime      :        评论时间
    */
    function getUserOrdersComment(uint _idx, address _addr) public view returns (bool, string memory, uint, uint, string memory){
        bool  _exist =   userInfo[ _addr].orders[_idx].comment.exist;
        string storage _content = userInfo[ _addr].orders[_idx].comment.content;
        string storage _hash = userInfo[ _addr].orders[_idx].comment.hash;

        uint _score = userInfo[ _addr].orders[_idx].comment.score;
        uint  _commentTime = userInfo[ _addr].orders[_idx].comment.time;
        return (_exist, _content, _score, _commentTime,_hash);
    }


    /*
    描述：获得景点评论
    参数： 
            _addr             :        用户地址
            _idx              :        订单编号
    返回值：
            _content          :        评价内容
            _hash             :        评论订单hash值
            _score            :        评分
            _commentTime      :        评论时间
    */
    function getUserSceneOrdersComment(uint _idx, address _addr) public view returns (bool, string memory, uint, uint, string memory){
        bool  _exist =   userInfo[ _addr].orders1[_idx].comment.exist;
        string storage _content = userInfo[ _addr].orders1[_idx].comment.content;
        string storage _hash = userInfo[ _addr].orders1[_idx].comment.hash;

        uint _score = userInfo[ _addr].orders1[_idx].comment.score;
        uint  _commentTime = userInfo[ _addr].orders1[_idx].comment.time;
        return (_exist, _content, _score, _commentTime, _hash);
    }

    //获取用户的余额
    function getUserMoney(address _addr) public view returns (uint) {
        return userInfo[_addr].Owner_money;
    }


    // 得到用户酒店订单数量
    function getUserOrdersCount(address _addr) public view returns(uint) {
        return userInfo[_addr].orders.length;
    }
    
    //得到用户景点订单数量
    function getUserSceneCount(address _addr) public view returns(uint) {
        return userInfo[_addr].orders1.length;
    }

    // 设置用户酒店订单Hash
    function setUserOrderTx(address _addr, string memory txHash) public {
        uint index = userInfo[_addr].orders.length;
        userInfo[_addr].orders[index - 1].hash = txHash;
    }

    // 设置用户酒店评论Hash
    function setUserOrderCommentTx(address _addr, uint _idx, string memory txHash) public {
        userInfo[_addr].orders[_idx].comment.hash = txHash;
    }

    // 设置用户旅游订单hash
    function setUserSceneOrderTx(address _addr, string memory txHash) public {
        uint index = userInfo[_addr].orders1.length;
        userInfo[_addr].orders1[index - 1].hash = txHash;
    }

    // 设置用户旅游评论hash
    function setUserSceneOrderCommentTx(address _addr, uint _idx, string memory txHash) public {
        userInfo[_addr].orders1[_idx].comment.hash = txHash;
    }

}

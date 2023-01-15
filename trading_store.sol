// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./util/IERC20.sol";

contract Store{
    // must match with IERC20 interface
   address private medium0;
   address private medium1; 

   string  medium0Name;
   string  medium1Name;

   // method selector(调用erc20转账)
   bytes4 private constant Selector =bytes4(keccak256(bytes("transfer(address,uint256)")));

   uint112 public medium0Num=100000;
   uint112 public medium1Num=100000;
   address private creator;
   uint32 private blockTimestrampLast;
   uint public K=200000;
   uint private lock =0;
   event swapEvent(address indexed customer,string tokenType,uint tokenNumber);
   constructor(){
     creator=msg.sender;
   }
   // 类似于分布式锁串行化交易,交易安全性拉满
   modifier locked(){
        require(lock ==0,"store is used by other");
        lock=1;
        _;
        lock=0;
   }
   //原型模式(输入时自己检查是否匹配ERC20 interface)
   function initialize(address _medium0,address _medium1)external{
     medium0=_medium0;
     medium1=_medium1;
     medium0Name=IERC20(medium0).name();
     medium1Name=IERC20(medium1).name();
   }
   //获取当前商店状态,能无gas消耗;
   function getStoreInfo()public view returns(uint112 _medium0Num,uint112 _medium1Num,uint32 _blockTimestrampLast){
        _medium0Num=medium0Num;
        _medium1Num=medium1Num;
        _blockTimestrampLast=blockTimestrampLast;
   }
   /**
    * 使用k值大概计算滑点损失后我能获得的数量
    */
   function calculateNums(uint112 _medium0Input,uint112 _medium1Input)internal view returns(uint112 _medium0Get,uint112 _medium1Get,uint32 lastTime){
           (uint112 tempNums0,uint112 tempNums1)=calculateTokenNumber(_medium0Input,_medium1Input);
           _medium0Get=uint112(_medium1Input*(tempNums0*10**6/tempNums1)/10**6);
           _medium1Get=uint112(_medium0Input*(tempNums1*10**6/tempNums0)/10**6);
           lastTime=blockTimestrampLast;
   }
   /**
       
   */
   function calculateTokenNumber(uint112 _medium0Input,uint112 _medium1Input)internal view returns(uint112 _medium0,uint112 _medium1){
     require( (_medium0Input>0) || (_medium1Input>0),"please promise you should exchange goods greater than zero");
           if(_medium0Input<0){
             _medium0Input=0;
           }  
           if(_medium1Input<0){
            _medium1Input=0;
           }
           uint112 NewNums0=medium0Num+_medium0Input;
           uint112 NewNums1=medium1Num+_medium1Input;
           uint tempk=NewNums0+NewNums1;
           //精度损失造成,但是因为是向下进位，代理商不会损失就行,懒得改
           // 浮点数除法，保留六位小数,扩大分子因子
           uint256 ratio=K*10**6/tempk;
            _medium0=uint112(NewNums0*ratio/10**6);
            _medium1=uint112(K-_medium0);
}
   /**
    用户展示层:滑点预计算
   */
   function slipeCalFromToken0(uint112 _medium0Input)external view returns(uint  ratio){
     require(_medium0Input<medium0Num,"invaild input");
     //理论获得
     uint112 theoryObtain = uint112((_medium0Input * medium0Num*10**6/medium1Num)/10**6);
     //最终获得,排除手续费
      (,uint112 eventObtain,)= calculateNums(_medium0Input,0);
            require(theoryObtain-eventObtain>0,"invaild input");
      ratio=((theoryObtain-eventObtain)*10**6)/(theoryObtain*10**4);
   }
     /**
    用户展示层:滑点预计算用medium1购买medium0
   */
   function slipeCalFromToken1(uint112  _medium1Input)external view returns(uint ratio){
      require(_medium1Input<medium1Num,"invaild input");
      //理论获得
     uint112 theoryObtain = uint112((_medium1Input * medium1Num*10**6/medium0Num)/10**6);
     //最终获得,排除手续费
      (uint112 eventObtain,,)=calculateNums(0,_medium1Input);
    require(theoryObtain-eventObtain>0,"invaild input");
     ratio=((theoryObtain-eventObtain)*10**6)/(theoryObtain*10**4);

   }
   
    /**
  * AMM core function
  * _medium0Input  and _medium1Input must greater than zerp.
  */
   function swap(uint112 _medium0Input,uint112 _medium1Input,address to)internal locked{
          require(_medium0Input>0||_medium1Input>0,"cant valid the transaction params,please prove transaction numbers greater than zero");
          (uint112 _medium0Nums,uint112 _medium1Nums,)=getStoreInfo(); // 节约gas
          (uint112 _StoreGiven0,uint112 _StoreGiven1,)=calculateNums(_medium0Input, _medium1Input);
          //确保商店能够支付，同时保证了用户的其中一个输入必须大于0，还节省了gas
          require(_medium0Nums>_StoreGiven0&&_medium1Nums>_StoreGiven1,"store cant process enough goods to trade");        
          //交易token
          //user should obtain number =  service charge+actual obtain number
          if(_StoreGiven0>0){
             uint112 serviceCharge=_StoreGiven0*3/10**3;
            _safeTransaction(medium0, creator,serviceCharge );
            _safeTransaction(medium0, to, _StoreGiven0-serviceCharge);
            //用户给钱
            _safeTransaction(medium1,creator,_medium0Input);
          }
           if(_StoreGiven1>0){
             uint112 serviceCharge=_StoreGiven1*3/10**3;
            _safeTransaction(medium1, creator,serviceCharge );
            _safeTransaction(medium1, to, _StoreGiven1-serviceCharge);
            //用户给钱
            _safeTransaction(medium0,creator,_medium1Input);
          }
          (medium0Num,medium1Num)=calculateTokenNumber(_medium0Input, _medium1Input);
   }

   function swapFromToken0(uint112 _mediumNums0)external{
      swap(_mediumNums0,0,msg.sender);
       emit swapEvent(msg.sender,medium0Name,_mediumNums0);
   }
   function swapFromToken1(uint112 _medium1Nums)external{
     swap(0,_medium1Nums,msg.sender);
     emit swapEvent(msg.sender,medium1Name,_medium1Nums);
   }

   /**
    * 保证不可见,同时降低函数耦合度
    */
   function _safeTransaction(address token,address to,uint value)private{
         (bool success,bytes memory data) = token.call(abi.encodeWithSelector(Selector, to,value));
         //确保交易正确，同时不会直接panic
         require(success&&(data.length == 0 || abi.decode(data,(bool))),"transaction failed,because the store given error");
   }
    
}
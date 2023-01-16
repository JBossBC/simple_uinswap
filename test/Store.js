const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
const { Contract } = require("hardhat/internal/hardhat-network/stack-traces/model");

describe("Store Contract",function(){
    //should be init two init token
    let ERC20A;
    let ERC20B;

    let storeObj;
    let tokenA;
    let tokenB;
    let k;
    let owner;
    let store_poolObj;
    let storeByPool=[];
    beforeEach(async function(){
        //不用 const,不然可达性分析能够保留store,后期可能会影响内存
      let store= await ethers.getContractFactory("Store");
      [owner, address1, address2, ...address] = await hre.ethers.getSigners();
       storeObj= await store.deploy();
      await storeObj.deployed();
      let result=await storeObj.getStoreInfo();
      tokenA=result._medium0Num.toNumber();
      tokenB=result._medium1Num.toNumber();  
      K=await storeObj.K();
      K=K.toNumber();
    })
    describe("Deployment", async function () {
        it("should be deployed store contract",async function(){
           expect(storeObj!=undefined&&storeObj!=null).true
        });
        it("should get right slipe point",async function(){
            const maxTestTimes=10;
            let sema=true;
            let failtureValuePairs={"theoryValue":undefined,"actualValue":undefined};
            for(let i=0;i<maxTestTimes;i++){
                //primise greater than zero
            let INPUT_A = Number.parseInt(Math.random()*25000)+1;
            let consumerValueMul100=await storeObj.slipeCalFromToken0(INPUT_A)
            consumerValueMul100=consumerValueMul100.toNumber();
            let  theoryValue;
            // 内置函数,减小内存开销
            (function(){
            //physical verify
               let origin=INPUT_A*tokenA*10**5/tokenB/10**5;
               let final=(tokenB - K/(tokenA+INPUT_A));
               //expand  molecule
               theoryValue= (origin-final)*10**6/(origin*10**4);
               theoryValue=Math.floor(theoryValue);
            }()
            )
            //solidity里面存在精度损失，这点还没改进。
             if(consumerValueMul100 != theoryValue &&consumerValueMul100+1!=theoryValue){
                  sema=false;
                  failtureValuePairs["theoryValue"]=theoryValue;
                  failtureValuePairs["actualValue"]=consumerValueMul100;
                  break;
             }
            }
            if(!sema){
                console.log("acturalValue is:",actualValue);
                console.log("theoryValue is:",theoryValue);
                expect(sema).true;
            }
        });
        it("should create store_pool",async function(){
            const store_pool=await ethers.getContractFactory("storeFactory");
            store_poolObj=await store_pool.deploy();
            await store_poolObj.deployed();
            expect(store_poolObj!=undefined&&store_poolObj!=null).true;
        });
        it("init two different token ",async function(){
            //就用这个代替了，反正都是ERC20
              let ERC20Facotry =await ethers.getContractFactory("FT");
              ERC20A =await ERC20Facotry.deploy("tokenA","xy");
              ERC20B =await ERC20Facotry.deploy("tokenB","xy");
              await ERC20A.deployed();
              await ERC20B.deployed();
              let result = ERC20A&&ERC20B?true:false;
              expect(result).true;
        });
        it("init a store object to store_pool",async function(){
            let tempStore = store_poolObj.createStore(ERC20A.address,ERC20B.address);
            storeByPool.push(tempStore);
            expect(tempStore!=undefined&&tempStore!=null).true
        });
        it("should promise the AMM function true",async function(){
            
        })   
})
  }) 
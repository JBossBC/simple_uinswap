const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");

describe("Store Contract",function(){
    let storeObj;
    let tokenA;
    let tokenB;
    let k;
    let owner;
    beforeEach(async function(){
      const store= await ethers.getContractFactory("Store");
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
        it("should get right slipe point",async function(){
            const maxTestLength=100000;
            let sema=true;
            let failtureValuePairs={"theoryValue":undefined,"actualValue":undefined};
            for(let i=0;i<maxTestLength;i++){
                //primise greater than zero
            let INPUT_A = Number.parseInt(Math.random()*25000)+1;
            let consumerValueMul100=await storeObj.slipeCalFromToken0(INPUT_A)
            consumerValueMul100=consumerValueMul100.toNumber();
            let  theoryValue;
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
        it("should promise the AMM function true",async function(){

        })   
})
  }) 
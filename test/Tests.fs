module Tests


open Xunit
open Nethereum.Web3
open System.IO
open Newtonsoft.Json.Linq
open Newtonsoft.Json
open System.Text

let ropstenTestNetUrl = "https://ropsten.infura.io/v3/68255eef637e4c7ba00bb2092bd1cbf9"
let ropstenTestNetSecret = "660501b6746a4d52a6b54e396bc8401e"


let localTestNetworkUrl = "http://127.0.0.1:7545"
let web3 = new Web3(ropstenTestNetUrl);

let votingContractAbi =
    JsonConvert.SerializeObject(JObject.Parse(File.ReadAllText(__SOURCE_DIRECTORY__ + "\\..\\build\\contracts\\VoterERC20.json")).GetValue("abi"))
    
let contractAddress = "0xf6765A5529EcB8132bE80e8E55C812B627a8234F"

let contract = web3.Eth.GetContract(votingContractAbi, contractAddress);

let fromAddress = "0x4564Ae538c0B3a5d11dD0D6780C3728bf135f7B2"


[<Fact>]
let ``Create voting`` () = async {

  //  web3.Personal.UnlockAccount.SendRequestAsync(contractAddress, "", new Nethereum.Hex.HexTypes.HexBigInteger("60")) |> Async.AwaitTask |> ignore;

    let accounts = web3.Eth.Accounts;

    let votingFunc = contract.GetFunction("createVoting")

    let! trans = votingFunc.CallAsync(functionInput=  [[|Encoding.ASCII.GetBytes("HI")|] ,60],from =fromAdress) |> Async.AwaitTask
    //let! trans = votingFunc.CallAsync(0) |> Async.AwaitTask

    Assert.Equal(0, 0 )
}




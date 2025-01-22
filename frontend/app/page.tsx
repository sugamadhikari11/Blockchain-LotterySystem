'use client'
import { useEffect, useState } from "react";
import { ethers } from "ethers";
import ContractAddress from "@/contratcs/contract-address.json";
import lotteryABI from "@/contratcs/Lottery.json";

interface StateType {
  provider: ethers.BrowserProvider | null;
  signer: any | null;
  contract: ethers.Contract | null;
}

const lotteryContractAddress = ContractAddress.Lottery;
const contractABI = lotteryABI.abi;
const HARDHAT_NETWORK_ID = "31337"; // Use your network ID here
export default function LotteryApp() {
  const [state, setState] = useState<StateType>({
    provider: null,
    signer: null,
    contract: null,
  });
  const [userAddress, setUserAddress] = useState<string | null>(null);
  const [accounts, setAccounts] = useState("None");
  const [inputAmount, setInputAmount] = useState("");
  const [players, setPlayers] = useState<string[]>([]); // To store players' addresses

  useEffect(() => {
    const connectWallet = async () => {
      const { ethereum } = window;

      if (ethereum) {
        try {
          window.ethereum.on("chainChanged", () => {
            window.location.reload();
          });

          window.ethereum.on("accountsChanged", () => {
            window.location.reload();
          });

          if (ethereum.networkVersion === HARDHAT_NETWORK_ID) {
            const account = await ethereum.request({
              method: "eth_requestAccounts",
            });

            const provider = new ethers.BrowserProvider(ethereum);
            const signer = await provider.getSigner(); // Ensure this is awaited
            const contract = new ethers.Contract(
              lotteryContractAddress,
              contractABI,
              signer
            );

            setAccounts(account);
            setUserAddress(account[0]);
            setState({ provider, signer, contract });

            // Get players list
            const playersList = await contract.getPlayers();
            setPlayers(playersList);
          } else {
            setUserAddress("Other Network");
          }
        } catch (error) {
          console.log(error);
        }
      } else {
        alert("Please install Metamask");
      }
    };

    connectWallet();
  }, []);

  const handleEnterLottery = async () => {
    if (!inputAmount || !userAddress) return alert("Please enter an amount");
    if (userAddress === "Other Network")
      return alert("Please Switch to Sepolia Network");

    try {
      const signer = await state.provider!.getSigner();
      const tx = await state.contract!.enterLottery({
        value: ethers.parseEther(inputAmount),
      });
      await tx.wait();
      alert("You have entered the lottery!");

      // Update players list after entering
      const playersList = await state.contract!.getPlayers();
      setPlayers(playersList);
    } catch (error) {
      console.error("Error entering lottery:", error);
    }
  };

  const handleDrawWinner = async () => {
    if (!userAddress) return alert("You cannot perform operation");
    if (userAddress === "Other Network")
      return alert("Please Switch to Sepolia Network");

    try {
      const signer = await state.provider!.getSigner();
      const tx = await state.contract!.drawWinner();
      await tx.wait();
      alert("Winner has been drawn!");

      // Fetch new players list after drawing the winner
      const playersList = await state.contract!.getPlayers();
      setPlayers(playersList);
    } catch (error) {
      console.error("Error drawing winner:", error);
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center">
      <div className="bg-white p-8 rounded shadow-md w-96">
        <h1 className="text-2xl font-bold mb-6 text-center">Lottery DApp</h1>
        <h1 className="text-sm font-bold mb-6 text-center">
          Your Address: {userAddress}
        </h1>
        <input
          type="number"
          className="w-full p-2 mb-4 border rounded"
          placeholder="Enter amount to join lottery (ETH)"
          value={inputAmount}
          onChange={(e) => setInputAmount(e.target.value)}
        />
        <div className="flex justify-around mb-4">
          <button
            onClick={handleEnterLottery}
            className="bg-blue-500 text-white px-4 py-2 rounded"
          >
            Enter Lottery
          </button>
          <button
            onClick={handleDrawWinner}
            className="bg-blue-500 text-white px-4 py-2 rounded"
          >
            Draw Winner
          </button>
        </div>
        <div className="mt-4">
          <h2 className="text-lg font-bold">Players:</h2>
          {players.length > 0 ? (
            <ul className="list-disc ml-5">
              {players.map((player, index) => (
                <li key={index}>{player}</li>
              ))}
            </ul>
          ) : (
            <p>No players have entered the lottery yet.</p>
          )}
        </div>
      </div>
    </div>
  );
}

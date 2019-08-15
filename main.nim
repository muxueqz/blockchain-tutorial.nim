import times
import strutils
import std/sha1
import jester

settings:
  port = Port(5003)
  bindAddr = "127.0.0.1"

type
  Block = object
    Index, BPM: int
    Timestamp, Hash, PrevHash: string

var Blockchain: seq[Block]

proc calculateHash(b: Block): string =
  var
    record = intToStr(b.Index) & b.Timestamp & intToStr(b.BPM) & b.PrevHash
  return $secureHash(record)

proc generateBlock(oldBlock: Block, BPM: int): Block =
    var
      newBlock: Block
    newBlock.Index = oldBlock.Index + 1
    newBlock.Timestamp = $getTime().toUnix()
    newBlock.BPM = BPM
    newBlock.PrevHash = oldBlock.Hash
    newBlock.Hash = calculateHash(newBlock)
    return newBlock

proc isBlockValid(newBlock, oldBlock: Block): bool =
  if oldBlock.Index+1 != newBlock.Index:
    return false
  if oldBlock.Hash != newBlock.PrevHash:
    return false
  if calculateHash(newBlock) != newBlock.Hash:
    return false
  return true

proc replaceChain(newBlocks: seq[Block]) =
  if len(newBlocks) > len(Blockchain):
    Blockchain = newBlocks

var
  genesisBlock: Block
genesisBlock.Index = 0
genesisBlock.Timestamp = $getTime().toUnix()
genesisBlock.BPM = 0
genesisBlock.PrevHash = ""
genesisBlock.Hash = ""
Blockchain.add genesisBlock

routes:
  get "/":
    resp $Blockchain
  post "/":
    var
      bpm = @"BPM"
      newBlock = generateBlock(Blockchain[len(Blockchain)-1], bpm.parseInt)
    if isBlockValid(newBlock, Blockchain[len(Blockchain)-1]):
      var newBlocks = deepCopy(Blockchain)
      newBlocks.add newBlock
      replaceChain(newBlocks)
    resp Http201, $newBlock

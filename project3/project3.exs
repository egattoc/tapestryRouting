defmodule Project3 do
  def start do
        numNodes = String.to_integer(Enum.at(System.argv(),0))
        numRequests = String.to_integer(Enum.at(System.argv(),1))
        MainModule.start(numNodes,numRequests)
  end
end
Project3.start
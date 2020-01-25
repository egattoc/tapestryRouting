defmodule Routing do

    # spawning a separate process for every node
    def startRouting(numRequests,nodeList) do
        GenServer.start_link(TapeNode,{%{},[]}, name: String.to_atom("main"))
        Enum.map(nodeList, fn source->
            spawn(fn -> sendRequest(numRequests,source,nodeList)end)
        end)
    end

    def completeRequests(numRequests,st,nodeList) do
        Process.sleep(5)
        hopsList = hopsCount()
        if(Enum.count(hopsList) >= Enum.count(nodeList)*numRequests) do
            maxHop = Enum.max(hopsList)
            IO.puts("#{inspect maxHop}")
            et = System.os_time(:millisecond)
            IO.puts((et-st)/1000)
            System.halt(0)
        end
        completeRequests(numRequests,st,nodeList)
    end

    # spawning a separate process for each request of each node
    def sendRequest(numRequests,source,nodeList) do
        Enum.map(1..numRequests, fn x->
            spawn(fn -> routeToNeighbour(source,source,Enum.random(nodeList--[source]),0) end)
            Process.sleep(1000)
        end)
    end

    def hopsCount() do
        hop = GenServer.call(String.to_atom("main"),{:getState},:infinity)
        hop
    end


    # assuming that a path from every source to every destination exists, there is no exit condition
    # also, storing the maximum value of hops encountered in the state of source node
    def routeToNeighbour(source,intermediate,destination,numHops) do
        # IO.puts(source <> "   " <> intermediate <> "   " <> destination)
        level = Enum.reduce_while(0..String.length(intermediate)-1, 1, fn x, acc ->
        if String.slice(intermediate,0..x) == String.slice(destination,0..x), do: {:cont, acc + 1}, else: {:halt, acc}
        end)
        searchEntry = String.at(destination,level-1)
        neighbours = TapeNode.showNeighbours(intermediate)
        nextHop = neighbours[level][searchEntry]
        if nextHop == destination do
            GenServer.cast(:main,{:updateHops,numHops})
        else
            routeToNeighbour(source,nextHop,destination,numHops + 1)
        end
    end
end
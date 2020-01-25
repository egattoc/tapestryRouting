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
            System.halt(0)
        end
        completeRequests(numRequests,st,nodeList)
    end

    # spawning a separate process for each request of each node
    def sendRequest(numRequests,source,nodeList) do
        Enum.map(1..numRequests, fn x->
            spawn(fn -> routeToNeighbour(nodeList,source,source,Enum.random(nodeList--[source]),0) end)
            Process.sleep(1000)
        end)
    end

    def hopsCount() do
        hop = GenServer.call(String.to_atom("main"),{:getState},:infinity)
        hop
    end

    def replaceNeighbour(levelMap,intermediate,level,entry,nodeList) do
        levelNodes = Enum.filter(nodeList,fn(node) -> String.slice(node,0,level-1) == String.slice(intermediate,0,level-1) end)
        entryMatches = Enum.filter(levelNodes, fn(x) ->  String.at(x,level-1) == entry end)
        intNodeHash = String.to_integer(intermediate,16)
        if(entryMatches != []) do
            {hashValue,_} = Enum.min_by(Enum.map(entryMatches, fn x -> {x, abs(String.to_integer(x,16) - intNodeHash) } end), fn({x,y}) -> y end)
            levelMap = put_in(levelMap[entry],hashValue)
        else
            levelMap = put_in(levelMap[entry],entryMatches)
        end
    end
 
    # assuming that a path from every source to every destination exists, there is no exit condition
    # also, storing the maximum value of hops encountered in the state of source node
    def routeToNeighbour(nodeList,source,intermediate,destination,numHops) do
        level = Enum.reduce_while(0..String.length(intermediate)-1, 1, fn x, acc ->
        if String.slice(intermediate,0..x) == String.slice(destination,0..x), do: {:cont, acc + 1}, else: {:halt, acc}
        end)
        searchEntry = String.at(destination,level-1)
        neighbours = TapeNode.showNeighbours(intermediate)
        nextHop = neighbours[level][searchEntry]
        if nextHop == destination do
            GenServer.cast(:main,{:updateHops,numHops})
        else
            if Process.whereis(String.to_atom("h_" <> nextHop)) == nil do
                levelMap = replaceNeighbour(neighbours[level],intermediate,level,searchEntry,nodeList)
                neighbours = put_in(neighbours[level],levelMap)
                GenServer.cast(String.to_atom("h_" <> intermediate),{:initialiseNeighbours,neighbours})
                routeToNeighbour(nodeList,source,intermediate,destination,numHops)
            else
                routeToNeighbour(nodeList,source,nextHop,destination,numHops + 1)
            end
        end
    end
end
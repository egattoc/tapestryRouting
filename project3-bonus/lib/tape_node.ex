defmodule TapeNode do
    use GenServer
 
    def start_link(hashValue) do
        GenServer.start_link(__MODULE__,{%{},[]}, name: String.to_atom("h_" <> hashValue))
    end
 
    def init(state) do
        Process.flag(:trap_exit, true)
        {:ok, state}
    end

    def handle_call({:stop_process}, _from, state) do
        {:stop, :normal,:ok, state}
    end
    
    def handle_cast({:joinNetwork, newNodeHash, nodeHash}, state) do
        level = Enum.reduce_while(0..String.length(newNodeHash)-1, 1, fn x, acc ->
        if String.slice(newNodeHash,0..x) == String.slice(nodeHash,0..x), do: {:cont, acc + 1}, else: {:halt, acc}
        end)
        searchEntry = String.at(newNodeHash,level-1)
        neighbourMap = elem(state,0)
        replaceNode = neighbourMap[level][searchEntry]
        if(replaceNode != []) do
            newNodeHash = Enum.min_by([replaceNode,newNodeHash], fn x -> abs(String.to_integer(x,16)-String.to_integer(nodeHash,16)) end)
        end
        neighbourMap = put_in(neighbourMap[level][searchEntry],newNodeHash)
        newState = put_elem(state,0,neighbourMap)
        {:noreply,newState}
    end
 

    def handle_cast({:initialiseNeighbours,neighbours},state) do
        newState = put_elem(state,0,neighbours)
        {:noreply,newState}
    end


    def handle_cast({:updateHops,numHops},state) do
        hops = elem(state,1)
        hops = hops ++ [numHops]
        state = put_elem(state,1,hops)
        {:noreply,state}
    end
 

    def handle_call({:showNeighbours},from,state) do 
        {:reply,elem(state,0),state}
    end


    def handle_call({:getState}, _from, state) do
        {:reply, elem(state,1), state}
    end

    def showNeighbours(node) do
        GenServer.call(String.to_atom("h_" <> node),{:showNeighbours})
    end


    def initNeighborMap(nodeHash,listOfNodes,level) do
        neighbourMap = getNeighbours(%{},nodeHash,listOfNodes,level)
        GenServer.cast(String.to_atom("h_" <> nodeHash),{:initialiseNeighbours,neighbourMap})
    end

    def getNeighbours(neighbourMap,nodeHash,listOfNodes,0), do: neighbourMap


    def getNeighbours(neighbourMap,nodeHash,listOfNodes,level) do
        listOfNodes = listOfNodes -- [nodeHash]
        levelNodes = Enum.filter(listOfNodes,fn(node) -> String.slice(node,0,level-1) == String.slice(nodeHash,0,level-1) end)
        levelMap = getLevelMap(nodeHash,%{},levelNodes,level,15)
        listOfNodes = listOfNodes -- levelNodes
        neighbourMap = put_in(neighbourMap[level],levelMap)
        getNeighbours(neighbourMap,nodeHash,listOfNodes,level-1)
    end

    def joinNetwork(newNodeHash, listOfNodes, level) do
    # for all nodes except newNode, check if newNode will be placed in the neighbourMap
        Enum.each(listOfNodes -- [newNodeHash], fn x-> GenServer.cast(String.to_atom("h_" <> x),{:joinNetwork,newNodeHash,x}) end)
    # create neighbourMap for newNode passing a list of ALL nodes, because the source node is removed from the list in getNeighbours
        initNeighborMap(newNodeHash,listOfNodes, level)
    end

    def getLevelMap(nodeHash,levelMap,levelNodes,level,-1), do: levelMap

    def getLevelMap(nodeHash,levelMap,levelNodes,level,entry) do
        entryMatches = Enum.filter(levelNodes, fn(x) ->  String.at(x,level-1) == Integer.to_string(entry,16) end)
        if(entryMatches != []) do
          {hashValue,_} = Enum.min_by(Enum.map(entryMatches, fn x -> {x, abs(String.to_integer(x,16) - String.to_integer(nodeHash,16)) } end), fn({x,y}) -> y end)
          levelMap = put_in(levelMap[Integer.to_string(entry,16)],hashValue)
          getLevelMap(nodeHash,levelMap,levelNodes,level,entry-1)
        else
          levelMap = put_in(levelMap[Integer.to_string(entry,16)],entryMatches)
          getLevelMap(nodeHash,levelMap,levelNodes,level,entry-1)
        end
    end
 
end
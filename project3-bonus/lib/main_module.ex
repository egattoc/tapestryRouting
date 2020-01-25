defmodule MainModule do
    def start(numNodes,numRequests,failedPercentage) do
        level = 8
        entry = 15
        failedNumber = trunc((failedPercentage/100) * numNodes)
        :ets.new(:table, [:bag, :named_table,:public])

        Enum.each(1..numNodes-1, fn i-> hashValue = String.slice(:crypto.hash(:sha, "Node_" <> Integer.to_string(i)) |> Base.encode16,0..7)
        nodeName = "Node_" <> Integer.to_string(i)
        :ets.insert(:table, {"Nodes", {hashValue, nodeName}})
        TapeNode.start_link(hashValue)
        end)
        nodes = :ets.lookup(:table, "Nodes")
        listOfNodes = Enum.map(nodes, fn {_,{a,_}} -> a end)
        # IO.inspect(listOfNodes)
        st = System.os_time(:millisecond)
        Enum.each(listOfNodes,fn x-> 
        TapeNode.initNeighborMap(x,listOfNodes,level) end)

        #Joining a new node
        hashValue = String.slice(:crypto.hash(:sha, "Node_" <> Integer.to_string(numNodes)) |> Base.encode16,0..7)
        nodeName = "Node_" <> Integer.to_string(numNodes)
        :ets.insert(:table, {"Nodes", {hashValue, nodeName}})
        listOfNodes = listOfNodes ++ [hashValue]
        TapeNode.start_link(hashValue)
        TapeNode.joinNetwork(hashValue,listOfNodes,level)

        # Deleting nodes, as per percentage
        failedNodes = Enum.map(1..failedNumber, fn x-> Enum.random(listOfNodes) end)
        Enum.each(failedNodes, fn x-> 
        if Process.whereis(String.to_atom("h_" <> x)) != nil do
            GenServer.call(String.to_atom("h_" <> x),{:stop_process})
        end
        end)
        listOfNodes = listOfNodes -- failedNodes
    
        #Routing for nodes for number of requests
        Routing.startRouting(numRequests,listOfNodes)
        Routing.completeRequests(numRequests,st,listOfNodes)
    end
end
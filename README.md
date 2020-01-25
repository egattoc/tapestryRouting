# Project3

**TODO: Add description**

Team Members:

Anushka Linge (UFID: 77530821)
Dipen Jain (UFID: 15521903)

Instruction:

1. Unzip project3.zip and navigate to project3 folder.
2. Open the command prompt and enter the below mix command to compile and run the code.

    Input: Enter numNodes followed by numRequests
    numNodes is the number of the total nodes in the network, out of which one dynamically joins the network later. numRequests is the number of requests that is sent by each node in the network.

    Output: The maximum number of hops it took to send a request to a random destination (from among all the nodes)

    mix run project3.exs numNodes numRequests

3. Input: mix run project3.exs  100 10
   Output: 2

   Input: mix run project3.exs  1000 10
   Output: 4

4. Operation
    i. A network is first created of (numNodes - 1) nodes.
    ii. The routing tables of these nodes is created.
    iii. One node dynamically joins this existing network of nodes. At this point, we send a multicast message to other nodes in the existing network to update their routing table if required.
    iv. The new node creates it's routing table by scanning the network.
    iv. All the nodes in the network now send a request per second, to a destination node which was selected at random. So a total of (numNodes * numRequests) are made. 
    v. From among all these requests, the maximum number of hops encountered is finally printed as the output of the program.

5. What is working:
    The program is working as expected and returns the maximum number of hops. Below is the upper limit of number of nodes for which the function ran and was tested on:

    Maximum network and number of requests the code worked and was tested for is : 
    numNodes = 1000 numRequests = 200 - maxHops = 4 - time took 688.782 sec
    numNodes = 2000 numRequests = 45 - maxHops = 4 - time took 298.41 sec
    numNodes = 3000 numRequests = 5 - maxHops = 4 - time took 200 sec

5. Implementation Details:

    Joining Network : 
        In this implementation join network has been shown for 1 node, where the new node multicasts the message to the network that it wants to join, and the nodes, check if the new node is a better fit in their routing table or not and add the new node accordingly. The new node creates it's routing table accordingly.
    

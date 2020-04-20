# TTK4145 Real-time Programming Elevator
This elevator was written in Elixir as part of the TTK4145 Real-time Programming course at the Norwegian University of Science and Technology.

## Architecture
### Overview
Upon startup, nodes on the same network will automatically find each other and connect, creating a cluster of nodes, each node controlling one elevator.

The flow of information during normal operation can be described roughly in pseudocode 

```
Boot all modules
Look for new nodes on the network, and add to our cluster
ButtonPollers poll the Driver

When button is pushed
  Add the order to all watchdogs in the cluster
  If the order is a cab order
    Add the order to a queue of orders on the node the button was pressed
  If the order is of any other type
    Bidhandler asks all nodes in cluster for a bid on the order
      Each node returns a bid based on a cost function
    Bidhandler chooses the best bid
    Add order to queue of orders on the selected node
```
Once an order is in the order queue, the FSM will pop off the top element and communicate with the elevator through the Driver layer.


### Modules
The program consists of several modules. It is written mostly using GenServer calls and casts to more easily facilitate communication across different nodes on the network.

#### Driver
Controls the elevator through a TCP port. Contains all the functions necessary to control all the features on the elevator. We can get and set lights, we can fetch what floor the elevator is on, set motor direction, etc... 

#### Poller
Polls all the buttons on the elevator and communicates with the BidHandler and OrderHandler.
      
#### Watchdog
Makes sure all orders are completed. Will redistribute orders to other elevators if they take too long to complete.
      
#### OrderHandler
Handles the request queue and order queue on the current node.

#### Agents.FSMRestartCounter
Agent which makes sure the elevator is only restarted once when a cab order is not cleared in time.
      
#### Agents.Direction
Agent to keep track of the direction of travel.

#### Agents.Floor
Agent to keep track of current floor.

#### Agents.Door
Agent to keep track of door state.

#### ElevatorFSM
Finite State Machine for the elevator.

#### BidHandler
Communicates with other nodes to facilitate which node gets an order.

## Installation

### Install elixir
Add Erlang Solutions repo
`wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && sudo dpkg -i erlang-solutions_2.0_all.deb`
Update package manager
`sudo apt-get update`
Install the Erlang/OTP platform and all of its applications
`sudo apt-get install esl-erlang`
Install Elixir
`sudo apt-get install elixir`

### Install tmux
Assuming you're on Ubuntu/Debian
`apt install tmux`

### Install elevator simulator
The elevator can be run as a D simulator found here
https://github.com/TTK4145/Simulator-v2

### Edit main.ex
Change the directory of the SimElevatorServer calls to the directory where you downloaded the simulator

## Running the program
To run the elevator, open any terminal window and run
```bash
mix compile && mix escript.build && ./elevator 0
```

## Credits
GenStateMachine was used for the FSM.

Thank you to Jostein Løwer for the Driver library, and help with functions regarding registering processes, connecting nodes, and polling buttons.
